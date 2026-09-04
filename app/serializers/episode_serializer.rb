class EpisodeSerializer
  include Alba::Resource
  include LibraryAttributes

  attributes :id, :number, :title, :duration_seconds, :audio_tracks, :subtitle_tracks

  attribute :thumbnail_url do |episode|
    next nil unless episode.thumbnail.attached?

    Rails.application.routes.url_helpers.rails_blob_url(episode.thumbnail, host: params[:request].base_url)
  end

  attribute :user_progress_seconds do |episode|
    episode.user_progress(params[:user])
  end
end
