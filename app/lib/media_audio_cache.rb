class MediaAudioCache
  def initialize(media_item, root: Rails.root)
    @media_item = media_item
    @root = root
  end

  def exist?(track_index)
    File.exist?(path(track_index))
  end

  def path(track_index)
    cache_dir.join("audio_track_#{track_index}.m4a")
  end

  def prepare!
    FileUtils.mkdir_p(cache_dir)
  end

  private

  def cache_dir
    @root.join("tmp", "audios", @media_item.id.to_s)
  end
end
