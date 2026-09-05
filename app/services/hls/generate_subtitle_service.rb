class Hls::GenerateSubtitleService
  Result = Data.define(:success, :stderr)

  CONVERSION_ARTIFACTS_RE = /\{=[^}]*\}/
  VTT_TAG_RE =
    /<\/?(?:b|i|u|ruby|rt|c(?:\.\w+)?|v(?:\s+voice="[^"]*")?|lang(?:\s+lang="[^"]*")?|[\d:.]{8,12})\s*>/

  def self.call(playable, track_index, output_path)
    new(playable, track_index, output_path).call
  end

  def initialize(playable, track_index, output_path)
    @playable = playable
    @track_index = track_index
    @output_path = output_path
  end

  def call
    stdout, stderr, status = Open3.capture3(*ffmpeg_command)

    if status.success? && File.exist?(@output_path) && File.size(@output_path).positive?
      sanitize_vtt(@output_path)
      Result.new(success: true, stderr: stderr)
    else
      File.delete(@output_path) if File.exist?(@output_path)
      Result.new(
        success: false,
        stderr: stderr.presence || "ffmpeg failed or produced empty subtitle file"
      )
    end
  end

  private

  def ffmpeg_command
    [
      "ffmpeg", "-y",
      "-v", "error",
      "-i", @playable.file_path,
      "-map", "0:s:#{@track_index}",
      "-f", "webvtt",
      @output_path.to_s
    ]
  end

  def sanitize_vtt(file_path)
    content = File.read(file_path)
    cleaned_content = content.gsub(CONVERSION_ARTIFACTS_RE, "").gsub(VTT_TAG_RE, "")
    File.write(file_path, cleaned_content)
  end
end
