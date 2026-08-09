class MediaMetadataService
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
      "-select_streams", "s",
      @file_path.to_s
    )

    unless status.success?
      error = RuntimeError.new(stderr.presence || "Error fetching metadata (Exit code: #{status.exitstatus})")
      ApplicationLogger.error(error, location: "MediaMetadataService")
      return []
    end

    streams = JSON.parse(stdout)["streams"] || []
    format_streams(streams)
  end

  def format_streams(streams)
    streams.map.with_index do |stream, relative_index|
      tags = stream["tags"] || {}
      {
        id: relative_index,
        stream_index: stream["index"],
        language: tags["language"] || "und",
        label: tags["title"] || tags["language"] || "Subtitle #{relative_index + 1}"
      }
    end
  end
end
