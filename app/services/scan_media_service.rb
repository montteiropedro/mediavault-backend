class ScanMediaService
  SUPPORTED_EXTENSIONS = %w[.mp4 .mkv .avi .mov .mp3 .flac].freeze

  def self.call(library_path = "/media/library")
    new(library_path).call
  end

  def initialize(library_path)
    @library_path = library_path
  end

  def call
    puts "Starting media scan in: #{@library_path}..."

    unless Dir.exist?(@library_path)
      puts "Directory #{@library_path} does not exist."
    end

    existing_files_on_disk = []
    scanned_count = 0

    # Recursively scans the disk and indexes/updates the files found
    Dir.glob(File.join(@library_path, "**", "*")).each do |file_path|
      next unless supported_file?(file_path)

      existing_files_on_disk << file_path
      process_file(file_path)
      scanned_count += 1
    end

    # Remove from the database the items whose files have been deleted from the disk
    removed_count = cleanup_missing_records(existing_files_on_disk)

    puts "Scan completed! Processed #{scanned_count} files. Removed #{removed_count} missing records."
  end

  private

  def supported_file?(file_path)
    File.file?(file_path) && SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
  end

  def process_file(file_path)
    # Extract filename without extension to use as default title
    filename = File.basename(file_path, File.extname(file_path))
    clean_title = filename.humanize.titleize

    # Create or update the MediaItem based on file_path
    media_item = MediaItem.find_or_initialize_by(file_path: file_path)
    return unless media_item.new_record?

    media_item.assign_attributes(
      title: clean_title,
      media_type: video_or_audio(file_path),
      description: "Auto-indexed from local storage."
    )

    if media_item.save
      puts "Indexed new media: #{clean_title}"
      MediaMetadataProcessingJob.perform_later(media_item.id)
    else
      puts "Failed to index #{file_path}: #{media_item.errors.full_messages.join(', ')}"
    end
  end

  def cleanup_missing_records(files_on_disk)
    # Retrieves records from the database that are NOT among the files found on the disk.
    missing_items = MediaItem.where.not(file_path: files_on_disk)
    removed_count = missing_items.count

    if removed_count.positive?
      missing_items.find_each do |item|
        puts "Removing missing media from database: #{item.title} (#{item.file_path})"
      end
      # destroy_all triggers dependencies and callbacks (e.g., cleans up attachments in Active Storage).
      missing_items.destroy_all
    end

    removed_count
  end

  def video_or_audio(file_path)
    ext = File.extname(file_path).downcase
    %w[.mp3 .flac].include?(ext) ? :audio : :video
  end
end
