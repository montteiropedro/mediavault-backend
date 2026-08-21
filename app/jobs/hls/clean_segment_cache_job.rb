class Hls::CleanSegmentCacheJob < ApplicationJob
  RETENTION_PERIOD = 24.hours

  def perform
    cache_base_dir = Hls::SegmentCache::DEFAULT_BASE_DIR

    unless Dir.exist?(cache_base_dir)
      ApplicationLogger.info("cache_base_dir not found", location: "Hls::CleanSegmentCacheJob")
      return
    end

    cutoff_time = RETENTION_PERIOD.ago

    Dir.glob(cache_base_dir.join("**", "*.ts")).each do |file_path|
      if File.mtime(file_path) < cutoff_time
        begin
          File.delete(file_path)
        rescue => e
          ApplicationLogger.warn(e.message, location: "Hls::CleanSegmentCacheJob", context: { file_path: })
        end
      end
    end

    Dir.glob(cache_base_dir.join("*")).each do |dir|
      if Dir.exist?(dir) && Dir.empty?(dir)
        begin
          Dir.rmdir(dir)
        rescue => e
          ApplicationLogger.warn(e.message, location: "Hls::CleanSegmentCacheJob", context: { dir: })
        end
      end
    end
  end
end
