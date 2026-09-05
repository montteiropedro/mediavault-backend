class Hls::CleanCacheJob < ApplicationJob
  RETENTION_PERIOD = 24.hours

  def perform
    cache_base_dir = Hls::Base::DEFAULT_BASE_DIR

    unless Dir.exist?(cache_base_dir)
      ApplicationLogger.info("cache_base_dir not found", location: "Hls::CleanCacheJob")
      return
    end

    cutoff_time = RETENTION_PERIOD.ago

    Dir.glob(cache_base_dir.join("**", "*.{ts,vtt}")).each do |file_path|
      if File.mtime(file_path) < cutoff_time
        begin
          File.delete(file_path)
        rescue => e
          ApplicationLogger.warn(e.message, location: "Hls::CleanCacheJob", context: { file_path: })
        end
      end
    end

    directories =
      Dir.glob(cache_base_dir.join("**", "*"))
        .select { |f| File.directory?(f) }
        .sort_by(&:length)
        .reverse

    directories.each do |dir|
      if Dir.exist?(dir) && Dir.empty?(dir)
        begin
          Dir.rmdir(dir)
        rescue => e
          ApplicationLogger.warn(e.message, location: "Hls::CleanCacheJob", context: { dir: })
        end
      end
    end
  end
end
