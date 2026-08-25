class Library
  TYPES = {
    "movie" => Movie,
    "episode" => Episode,
    "show" => Show,
    "season" => Season
  }.freeze

  def self.find_item(id, type:)
    klass = TYPES.fetch(type) { raise ActiveRecord::RecordNotFound }
    klass.find(id)
  end
end
