class Hls::SubtitleCache
  attr_reader :base_dir

  def initialize(playable, base_dir: Hls::Base::DEFAULT_BASE_DIR)
    @playable = playable
    @base_dir = Pathname.new(base_dir)
  end

  def exist?(track_index)
    File.exist?(path(track_index))
  end

  def path(track_index)
    cache_dir.join("%03d.vtt" % track_index)
  end

  def prepare!
    FileUtils.mkdir_p(cache_dir)
  end

  private

  def cache_dir
    @base_dir.join(
      @playable.id.to_s,
      "subtitles",
    )
  end
end
