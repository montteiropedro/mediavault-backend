class MovieSerializer
  include Alba::Resource

  attributes :id, :title, :duration_seconds, :audio_tracks, :subtitle_tracks

  attribute :type do
    "movie"
  end

  attribute :cover_art_url do |movie|
    next nil unless movie.cover_art.attached?

    Rails.application.routes.url_helpers.rails_blob_url(movie.cover_art, host: params[:request].base_url)
  end

  attribute :user_progress_seconds do |movie|
    movie.user_progress(current_user)
  end
end
