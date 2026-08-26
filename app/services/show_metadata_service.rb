class ShowMetadataService
  SUPPORTED_COVER_NAMES = %w[cover.jpg cover.jpeg cover.png].freeze

  def self.call(show)
    new(show).call
  end

  def initialize(show)
    @show = show
  end

  def call
    attach_cover
  end

  private

  def attach_cover
    cover_path = find_cover
    return unless cover_path

    @show.cover_art.attach(
      io: File.open(cover_path),
      filename: "#{@show.id}_cover#{File.extname(cover_path).downcase}",
      content_type: Marcel::MimeType.for(cover_path)
    )
  end

  def find_cover
    SUPPORTED_COVER_NAMES
      .map { |name| File.join(@show.source_path, name) }
      .find { |path| File.file?(path) }
  end
end
