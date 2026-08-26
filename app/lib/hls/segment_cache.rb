class Hls::SegmentCache
  DEFAULT_BASE_DIR = Rails.root.join("storage", "hls_cache").freeze
  SEGMENT_DURATION_IN_SECONDS = 6

  attr_reader :base_dir

  def initialize(playable, base_dir: DEFAULT_BASE_DIR)
    @playable = playable
    @base_dir = Pathname.new(base_dir)
  end

  def exist?(index)
    File.exist?(path(index))
  end

  def path(index)
    cache_dir.join("segment%03d.ts" % index)
  end

  def prepare!
    FileUtils.mkdir_p(cache_dir)
  end

  def playlist
    lines = ["#EXTM3U", "#EXT-X-VERSION:3", "#EXT-X-TARGETDURATION:#{SEGMENT_DURATION_IN_SECONDS}", "#EXT-X-MEDIA-SEQUENCE:0"]
    total_segments.times do |i|
      lines << "#EXTINF:#{SEGMENT_DURATION_IN_SECONDS}.0,"
      lines << "#{"%03d" % i}.ts"
    end
    lines << "#EXT-X-ENDLIST"
    lines.join("\n")
  end

  private

  def total_segments
    duration = @playable.duration_seconds
    (duration.to_f / SEGMENT_DURATION_IN_SECONDS).ceil
  end

  def cache_dir
    @base_dir.join(@playable.id.to_s)
  end
end
