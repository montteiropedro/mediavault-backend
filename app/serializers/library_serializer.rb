class LibrarySerializer
  SERIALIZERS = {
    Movie => MovieSerializer,
    Episode => EpisodeSerializer,
    Show => ShowSerializer,
    Season => SeasonSerializer
  }.freeze

  def self.new(item, params:)
    serializer = SERIALIZERS.fetch(item.class)

    serializer.new(item, params:)
  end
end
