class MediaMetadataService
  Stream = Data.define(:id, :language, :label)
  Result = Data.define(:audios, :subtitles)

  def self.call(file_path)
    new(file_path).call
  end

  def initialize(file_path)
    @file_path = file_path
  end

  def call
    puts "Starting media metadata analysis in: #{@file_path}..."
    extract_streams
  end

  private

  def extract_streams
    stdout, stderr, status = Open3.capture3(
      "ffprobe",
      "-v", "quiet",
      "-print_format", "json",
      "-show_streams",
      @file_path.to_s
    )

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Error fetching metadata (Exit code: #{status.exitstatus})")
      ApplicationLogger.error(error, location: "MediaMetadataService")
      return Result.new(audios: [], subtitles: [])
    end

    streams = JSON.parse(stdout)["streams"] || []
    audios = streams.select { |stream| stream["codec_type"] == 'audio' };
    subtitles = streams.select { |stream| stream["codec_type"] == 'subtitle' };

    Result.new(audios: format_streams(audios), subtitles: format_streams(subtitles))
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
end
