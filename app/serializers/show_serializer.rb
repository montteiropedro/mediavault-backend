class ShowSerializer
  include Alba::Resource
  include LibraryAttributes

  attributes :id, :title

  attribute :type do
    "show"
  end

  attribute :cover_art_url do |show|
    next nil unless show.cover_art.attached?

    Rails.application.routes.url_helpers.rails_blob_url(show.cover_art, host: params[:request].base_url)
  end

  many :seasons, resource: SeasonSerializer
end
