class Hls::GenerateVideoSegmentService
  Result = Data.define(:success, :stderr)

  def self.call(playable, segment_index, output_path)
    new(playable, segment_index, output_path).call
  end

  def initialize(playable, segment_index, output_path)
    @playable = playable
    @segment_index = segment_index
    @output_path = output_path
  end

  def call
    stdout, stderr, status = Open3.capture3(*ffmpeg_command)

    if status.success? && File.exist?(tmp_path) && File.size(tmp_path) > 0
      File.rename(tmp_path, @output_path)
      Result.new(success: true, stderr: stderr)
    else
      File.delete(tmp_path) if File.exist?(tmp_path)
      Result.new(success: false, stderr: stderr.presence || "ffmpeg failed or produced empty video file")
    end
  end

  private

  def start_time
    @segment_index * Hls::Base::SEGMENT_DURATION_IN_SECONDS
  end

  def duration
    Hls::Base::SEGMENT_DURATION_IN_SECONDS
  end

  def tmp_path
    "#{@output_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
  end

  def ffmpeg_command
    [
      "ffmpeg", "-y",
      "-ss", start_time.to_s,
      "-i", @playable.file_path,
      "-t", duration.to_s,
      "-map", "0:V:0",
      "-c:v", "libx264",
      "-output_ts_offset", start_time.to_s,
      "-muxdelay", "0",
      "-f", "mpegts",
      tmp_path
    ]

    # [
    #   "ffmpeg", "-y",
    #   "-ss", start_time.to_s,
    #   "-i", @playable.file_path,
    #   "-map", "0:V:0",
    #   "-vf", "trim=start=0:duration=#{duration},setpts=PTS-STARTPTS+#{start_time}/TB",
    #   "-c:v", "libx264",
    #   "-f", "mpegts",
    #   "-mpegts_copyts", "1",
    #   tmp_path
    # ]
  end
end
