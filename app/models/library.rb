class Library
  MODEL_TO_TYPE = {
    Movie => "movie",
    Episode => "episode",
    Show => "show",
    Season => "season"
  }.freeze

  TYPE_TO_MODEL = MODEL_TO_TYPE.invert.freeze

  def self.find_item(id, type:)
    klass = TYPE_TO_MODEL.fetch(type.to_s.downcase) { raise ActiveRecord::RecordNotFound }
    klass.find(id)
  end

  def self.type_for(item)
    MODEL_TO_TYPE.fetch(item.class)
  end

  def self.playable_types
    TYPE_TO_MODEL.select { |_, klass| klass.include?(Playable) }.keys
  end

  def self.find_playable(id, type:)
    case type&.downcase
    when "movie" then Movie.find(id)
    when "episode" then Episode.find(id)
    else raise "Playable type not defined"
    end
  end
end
