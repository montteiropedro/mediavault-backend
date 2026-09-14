class Api::V1::LibraryController < ApplicationController
  def index
    movies = Movie.all.with_attached_cover_art
    shows = Show.includes(seasons: :episodes).all.with_attached_cover_art

    render json: {
      movies: MovieSerializer.new(movies, params: { user: current_user, request: request }).as_json,
      shows: ShowSerializer.new(shows, params: { user: current_user, request: request }).as_json
    }
  end

  def show
    item = Library.find_item(params[:id], type: params[:type])
    render json: LibrarySerializer.new(item, params: { user: current_user, request: request }).as_json
  rescue ActiveRecord::RecordNotFound
    render status: :not_found
  end

  def scan
    job = LibraryScanJob.perform_later
    render json: { job_id: job.job_id }, status: :ok
  rescue StandardError => e
    render json: { error: "Failed to scan library: #{e.message}" }, status: :internal_server_error
  end
end
