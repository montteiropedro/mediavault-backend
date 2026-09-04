class Hls::GenerateAudioSegmentService
  Result = Data.define(:success, :stderr)

  def self.call(playable, track_index, segment_index, output_path)
    new(playable, track_index, segment_index, output_path).call
  end

  def initialize(playable, track_index, segment_index, output_path)
    @playable = playable
    @track_index = track_index
    @segment_index = segment_index
    @output_path = output_path
  end

  def call
    _stdout, stderr, status = Open3.capture3(*ffmpeg_command)

    if status.success? && File.exist?(@output_path) && File.size(@output_path).positive?
      Result.new(success: true, stderr: stderr)
    else
      File.delete(@output_path) if File.exist?(@output_path)

      Result.new(
        success: false,
        stderr: stderr.presence || "ffmpeg failed or produced empty audio file"
      )
    end
  end

  private

  def start_time
    @segment_index * Hls::Base::SEGMENT_DURATION_IN_SECONDS
  end

  def duration
    Hls::Base::SEGMENT_DURATION_IN_SECONDS
  end

  def ffmpeg_command
    [
      "ffmpeg", "-y",
      "-ss", start_time.to_s,
      "-i", @playable.file_path.to_s,
      "-t", duration.to_s,
      "-map", "0:a:#{@track_index}",
      "-c:a", "aac",
      "-b:a", "192k",
      "-ac", "2",
      "-output_ts_offset", start_time.to_s,
      "-muxdelay", "0",
      "-f", "mpegts",
      @output_path.to_s
    ]
  end
end
