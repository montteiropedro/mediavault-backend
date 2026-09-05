class Hls::AudioCache
  attr_reader :base_dir

  def initialize(playable, track_index, base_dir: Hls::Base::DEFAULT_BASE_DIR)
    @playable = playable
    @track_index = track_index
    @base_dir = Pathname.new(base_dir)
  end

  def exist?(segment_index)
    File.exist?(path(segment_index))
  end

  def path(segment_index)
    cache_dir.join("segment%03d.ts" % segment_index)
  end

  def prepare!
    FileUtils.mkdir_p(cache_dir)
  end

  private

  def cache_dir
    @base_dir.join(
      @playable.id.to_s,
      "audio",
      @track_index.to_s
    )
  end
end
