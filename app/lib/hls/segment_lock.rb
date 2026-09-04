class Hls::SegmentLock
  BASE_DIR = Rails.root.join("tmp", "hls_locks").freeze

  def self.synchronize(playable_id, resource, index)
    lock_dir = BASE_DIR.join(playable_id.to_s, resource.to_s)
    FileUtils.mkdir_p(lock_dir)
    lock_path = lock_dir.join("#{index}.lock")

    File.open(lock_path, File::CREAT | File::RDWR) do |f|
      f.flock(File::LOCK_EX)
      yield
    end
  end
end
