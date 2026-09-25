class Playable::MetadataService
  Stream = Data.define(:id, :language, :label)

  def self.call(media)
    new(media).call
  end

  def initialize(media)
    @media = media
    @file_path = media.file_path
  end

  def call
    extract_and_persist
  end

  private

  def extract_and_persist
    stdout, stderr, status = Open3.capture3(
      "ffprobe",
      "-v", "quiet",
      "-print_format", "json",
      "-show_streams",
      "-show_format",
      @file_path
    )

    "ffprobe -v quiet -print_format json -show_streams -show_format"

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Error fetching metadata")
      ApplicationLogger.error(error, location: self.class.name)
      return false
    end

    parsed = JSON.parse(stdout)
    streams = parsed["streams"] || []
    format_info = parsed["format"] || {}

    video_streams = streams.select { |s| s["codec_type"] == "video" }
    audio_streams = streams.select { |s| s["codec_type"] == "audio" }
    subtitle_streams = streams.select { |s| s["codec_type"] == "subtitle" }

    main_video_stream = video_streams.find { |stream| !cover_stream?(stream) } || video_streams.first
    @media.codec_name = main_video_stream["codec_name"]&.downcase if main_video_stream && @media.respond_to?(:codec_name=)

    @media.duration_seconds = format_info["duration"].to_f.round
    @media.title = format_info["tags"]["title"] if format_info.dig("tags", "title").present?
    @media.audio_tracks = format_streams(audio_streams).map(&:to_h)
    @media.subtitle_tracks = format_streams(subtitle_streams).map(&:to_h)

    attach_cover(video_streams) if is_cover_attachable?
    attach_thumbnail if is_thumbnail_attachable?

    @media.save!
  end

  def format_streams(streams)
    streams.map.with_index do |stream, relative_index|
      tags = stream["tags"] || {}

      Stream.new(
        id: relative_index,
        language: tags["language"] || "und",
        label: tags["title"] || tags["language"] || "#{stream['codec_type']} #{relative_index + 1}"
      )
    end
  end

  def is_cover_attachable?
    @media.respond_to?(:cover_art)
  end

  def is_thumbnail_attachable?
    @media.respond_to?(:thumbnail)
  end

  def attach_cover(video_streams)
    cover_stream = video_streams.find { |stream| cover_stream?(stream) }
    return unless cover_stream

    codec_name = cover_stream["codec_name"]
    extension = extension_for(codec_name)
    tmp_path = Rails.root.join("tmp", "covers", "#{SecureRandom.uuid}.#{extension}")
    FileUtils.mkdir_p(tmp_path.dirname)

    _stdout, stderr, status = Open3.capture3(
      "ffmpeg", "-y",
      "-i", @file_path.to_s,
      "-map", "0:#{cover_stream['index']}",
      "-frames:v", "1",
      "-update", "1",
      "-c", "copy",
      tmp_path.to_s
    )

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Failed to extract cover")
      ApplicationLogger.error(error, location: self.class.name)
      return
    end

    @media.cover_art.attach(
      io: File.open(tmp_path),
      filename: "#{@media.id}_cover.#{extension}",
      content_type: Marcel::MimeType.for(tmp_path)
    )
  ensure
    File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
  end

  def attach_thumbnail
    tmp_path = Rails.root.join("tmp", "thumbnail", "#{SecureRandom.uuid}.jpg")
    FileUtils.mkdir_p(tmp_path.dirname)
    thumbnail_timestamp = (@media.duration_seconds.to_f * 0.3).round(2)

    _stdout, stderr, status = Open3.capture3(
      "ffmpeg", "-y",
      "-ss", thumbnail_timestamp.to_s,
      "-i", @file_path.to_s,
      "-map", "0:V:0",
      "-frames:v", "1",
      "-q:v", "2",
      tmp_path.to_s
    )

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Failed to extract thumbnail")
      ApplicationLogger.error(error, location: self.class.name)
      return
    end

    @media.thumbnail.attach(
      io: File.open(tmp_path),
      filename: "#{@media.id}_thumbnail.jpg",
      content_type: Marcel::MimeType.for(tmp_path)
    )
  ensure
    File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
  end

  def cover_stream?(stream)
    return true if stream.dig("disposition", "attached_pic") == 1

    tags = stream["tags"] || {}
    mimetype = tags["MIMETYPE"] || tags["mimetype"]
    filename = tags["FILENAME"] || tags["filename"]

    mimetype.to_s.start_with?("image/") || filename.to_s.match?(/\.(jpe?g|png|bmp|gif)\z/i)
  end

  def extension_for(codec_name)
    case codec_name
    when "mjpeg" then "jpg"
    when "png" then "png"
    when "bmp" then "bmp"
    when "gif" then "gif"
    else "jpg"
    end
  end
end
