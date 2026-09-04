# app/serializers/season_serializer.rb
class SeasonSerializer
  include Alba::Resource
  include LibraryAttributes

  attributes :id, :number

  attribute :type do
    "season"
  end

  many :episodes, resource: EpisodeSerializer
end
