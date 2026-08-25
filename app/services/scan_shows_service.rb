class ScanShowsService
  DEFAULT_SHOWS_PATH = ENV.fetch("DEFAULT_SHOWS_PATH", "/media/library/shows")
  SUPPORTED_EXTENSIONS = %w[.mp4 .mkv .avi .mov].freeze
  SUPPORTED_COVER_NAMES = %w[cover.jpg cover.jpeg cover.png].freeze
  SEASON_PATTERN = /\A(season|s)[\s_\-]?\d+\z/i

  def self.call(shows_path = DEFAULT_SHOWS_PATH)
    new(shows_path).call
  end

  def initialize(shows_path)
    @shows_path = shows_path
  end

  def call
    Rails.logger.info("Starting shows scan in: #{@shows_path}...")

    unless Dir.exist?(@shows_path)
      Rails.logger.info("Directory #{@shows_path} does not exist.")
      return
    end

    @existing_episode_paths = []
    @scanned_shows = 0

    Dir.children(@shows_path).sort.each do |entry_name|
      entry_path = File.join(@shows_path, entry_name)
      next unless File.directory?(entry_path)

      if show_dir?(entry_path)
        process_show(entry_name, entry_path)
      else
        # treated as a category folder (e.g. "animes"), where each child is a show
        process_category(entry_name, entry_path)
      end
    end

    removed_count = cleanup_missing_episodes(@existing_episode_paths)

    Rails.logger.info(
      "Scan completed! Processed #{@scanned_shows} shows. Removed #{removed_count} missing episodes."
    )
  end

  private

  def show_dir?(path)
    Dir.children(path).any? do |child|
      child_path = File.join(path, child)
      File.directory?(child_path) && season_like?(child)
    end
  rescue Errno::ENOENT
    false
  end

  def season_like?(name)
    name.match?(SEASON_PATTERN)
  end

  def process_category(category_name, category_path)
    Dir.children(category_path).sort.each do |show_name|
      show_path = File.join(category_path, show_name)
      next unless File.directory?(show_path)

      process_show(show_name, show_path)
    end
  end

  def process_show(name, path)
    unless show_dir?(path)
      Rails.logger.info("Skipping #{path}: no season-like subdirectories found.")
      return
    end

    show = Show.find_or_initialize_by(source_path: path)
    show.title = name.humanize.titleize if show.new_record?
    show.save!

    ShowMetadataService.call(show)

    @scanned_shows += 1

    Dir.children(path).sort.each do |season_name|
      season_path = File.join(path, season_name)
      next unless File.directory?(season_path) && season_like?(season_name)

      process_season(show, season_name, season_path)
    end
  end

  def process_season(show, season_name, season_path)
    number = season_name[/\d+/]&.to_i || 0

    season = show.seasons.find_or_initialize_by(number: number)
    season.title ||= "Season #{number}"
    season.source_path = season_path
    season.save!

    Dir.children(season_path).sort.each do |file_name|
      file_path = File.join(season_path, file_name)
      next unless supported_file?(file_path)

      @existing_episode_paths << file_path
      process_episode(season, file_path)
    end
  end

  def process_episode(season, file_path)
    filename = File.basename(file_path, File.extname(file_path))
    clean_title = filename.humanize.titleize
    episode_number = filename[/(?:e|ep)[\s_\-]?(\d+)/i, 1]&.to_i

    episode = Episode.find_or_initialize_by(file_path: file_path)
    return unless episode.new_record?

    episode.assign_attributes(
      season: season,
      title: clean_title,
      number: episode_number
    )

    if episode.save
      Rails.logger.info("Indexed new episode: #{show_title_for(season)} - #{clean_title}")
      Playable::MetadataProcessingJob.perform_later(episode)
    else
      Rails.logger.info("Failed to index #{file_path}: #{episode.errors.full_messages.join(', ')}")
    end
  end

  def show_title_for(season)
    season.show.title
  end

  def supported_file?(file_path)
    File.file?(file_path) && SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
  end

  def cleanup_missing_episodes(files_on_disk)
    missing = Episode.where.not(file_path: files_on_disk)
    removed_count = missing.count

    if removed_count.positive?
      missing.find_each do |episode|
        Rails.logger.info("Removing missing episode: #{episode.title} (#{episode.file_path})")
      end

      missing.destroy_all
    end

    Season.left_joins(:episodes).where(episodes: { id: nil }).destroy_all
    Show.left_joins(:seasons).where(seasons: { id: nil }).destroy_all

    removed_count
  end
end
