class MediaMetadataService
  Stream = Data.define(:id, :language, :label)

  def self.call(media_item)
    new(media_item).call
  end

  def initialize(media_item)
    @media_item = media_item
    @file_path = media_item.file_path
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
      @file_path.to_s
    )

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Error fetching metadata (Exit code: #{status.exitstatus})")
      ApplicationLogger.error(error, location: "MediaMetadataService")
      return false
    end

    parsed = JSON.parse(stdout)
    streams = parsed["streams"] || []
    format_info = parsed["format"] || {}

    video_streams = streams.select { |s| s["codec_type"] == "video" }
    audio_streams = streams.select { |s| s["codec_type"] == "audio" }
    subtitle_streams = streams.select { |s| s["codec_type"] == "subtitle" }

    @media_item.duration = format_info["duration"].to_f.round
    @media_item.audio_tracks = format_streams(audio_streams).map(&:to_h)
    @media_item.subtitle_tracks = format_streams(subtitle_streams).map(&:to_h)

    attach_cover(video_streams)

    @media_item.save!
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
      ApplicationLogger.error(error, location: "MediaMetadataService")
      return
    end

    @media_item.cover_art.attach(
      io: File.open(tmp_path),
      filename: "#{@media_item.id}_cover.#{extension}",
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
