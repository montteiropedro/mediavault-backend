class ScanMoviesService
  DEFAULT_MOVIES_PATH = ENV.fetch("DEFAULT_MOVIES_PATH", "/media/library/movies")
  SUPPORTED_EXTENSIONS = %w[.mp4 .mkv .avi .mov].freeze

  def self.call(movies_path = DEFAULT_MOVIES_PATH, progress: nil)
    new(movies_path).call(progress:)
  end

  def initialize(movies_path)
    @movies_path = movies_path
  end

  def call(progress:)
    Rails.logger.info("Starting movies scan in: #{@movies_path}...")

    unless Dir.exist?(@movies_path)
      Rails.logger.info("Directory #{@movies_path} does not exist.")
      return
    end

    files = Dir.glob(File.join(@movies_path, "**", "*")).select { |file_path| supported_file?(file_path) }
    new_movies = []

    files.each_with_index do |file_path, index|
      movie = process_file(file_path)
      new_movies << movie if movie
      progress&.step(index + 1, files.size)
    end

    removed_count = cleanup_missing_records(files)
    Rails.logger.info("Scan completed! Processed #{files.size} files. Removed #{removed_count} missing records.")

    new_movies
  end

  private

  def supported_file?(file_path)
    File.file?(file_path) && SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
  end

  def process_file(file_path)
    filename = File.basename(file_path, File.extname(file_path))
    clean_title = filename.humanize.titleize

    movie = Movie.find_or_initialize_by(file_path: file_path)
    return unless movie.new_record?

    movie.assign_attributes(title: clean_title)

    if movie.save
      Rails.logger.info("Indexed new movie: #{clean_title}")
      movie
    else
      Rails.logger.info("Failed to index #{file_path}: #{movie.errors.full_messages.join(', ')}")
      nil
    end
  end

  def cleanup_missing_records(files_on_disk)
    missing_items = Movie.where.not(file_path: files_on_disk)
    removed_count = missing_items.count

    if removed_count.positive?
      missing_items.find_each do |item|
        Rails.logger.info("Removing missing movie from database: #{item.title} (#{item.file_path})")
      end

      missing_items.destroy_all
    end

    removed_count
  end
end
