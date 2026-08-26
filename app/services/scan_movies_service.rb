class ScanMoviesService
  DEFAULT_MOVIES_PATH = ENV.fetch("DEFAULT_MOVIES_PATH", "/media/library/movies")
  SUPPORTED_EXTENSIONS = %w[.mp4 .mkv .avi .mov].freeze

  def self.call(movies_path = DEFAULT_MOVIES_PATH)
    new(movies_path).call
  end

  def initialize(movies_path)
    @movies_path = movies_path
  end

  def call
    Rails.logger.info("Starting movies scan in: #{@movies_path}...")

    unless Dir.exist?(@movies_path)
      Rails.logger.info("Directory #{@movies_path} does not exist.")
    end

    existing_files_on_disk = []
    scanned_count = 0

    Dir.glob(File.join(@movies_path, "**", "*")).each do |file_path|
      next unless supported_file?(file_path)

      existing_files_on_disk << file_path
      process_file(file_path)
      scanned_count += 1
    end

    removed_count = cleanup_missing_records(existing_files_on_disk)
    Rails.logger.info("Scan completed! Processed #{scanned_count} files. Removed #{removed_count} missing records.")
  end

  private

  def supported_file?(file_path)
    File.file?(file_path) && SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
  end

  def process_file(file_path)
    filename = File.basename(file_path, File.extname(file_path))
    clean_title = filename.humanize.titleize

    media = Movie.find_or_initialize_by(file_path: file_path)
    return unless media.new_record?

    media.assign_attributes(title: clean_title)

    if media.save
      Rails.logger.info("Indexed new media: #{clean_title}")
      Playable::MetadataProcessingJob.perform_later(media)
    else
      Rails.logger.info("Failed to index #{file_path}: #{media.errors.full_messages.join(', ')}")
    end
  end

  def cleanup_missing_records(files_on_disk)
    missing_items = Movie.where.not(file_path: files_on_disk)
    removed_count = missing_items.count

    if removed_count.positive?
      missing_items.find_each do |item|
        Rails.logger.info("Removing missing media from database: #{item.title} (#{item.file_path})")
      end

      missing_items.destroy_all
    end

    removed_count
  end
end
