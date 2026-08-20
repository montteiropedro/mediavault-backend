class Hls::GenerateSegmentService
  Result = Data.define(:success, :stderr)

  def self.call(media_item, index, output_path)
    start_time = index * Hls::SegmentCache::SEGMENT_DURATION_IN_SECONDS
    tmp_path = "#{output_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"

    stdout, stderr, status = Open3.capture3(
      "ffmpeg", "-y",
      "-ss", start_time.to_s,
      "-i", media_item.file_path,
      "-t", Hls::SegmentCache::SEGMENT_DURATION_IN_SECONDS.to_s,
      "-map", "0:v:0",
      "-map", "0:a:0",
      "-c:v", "libx264",
      "-c:a", "aac",
      "-output_ts_offset", start_time.to_s,
      "-muxdelay", "0",
      "-f", "mpegts",
      tmp_path
    )

    if status.success? && File.exist?(tmp_path) && File.size(tmp_path) > 0
      File.rename(tmp_path, output_path)
      Result.new(success: true, stderr: stderr)
    else
      File.delete(tmp_path) if File.exist?(tmp_path)
      Result.new(success: false, stderr: stderr.presence || "ffmpeg failed or produced empty file")
    end
  end
end
