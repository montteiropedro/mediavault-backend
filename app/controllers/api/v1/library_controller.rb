class Api::V1::LibraryController < ApplicationController
  def index
    movies = Movie.all.with_attached_cover_art
    shows = Show.includes(seasons: :episodes).all.with_attached_cover_art

    render json: {
      movies: MovieSerializer.new(movies, params: { request: request }).as_json,
      shows: ShowSerializer.new(shows, params: { request: request }).as_json
    }
  end

  def show
    item = Library.find_item(params[:id], type: params[:type])
    render json: serialize(item)
  rescue ActiveRecord::RecordNotFound
    render status: :not_found
  end

  def scan
    LibraryScanJob.perform_later
    render status: :ok
  rescue StandardError => e
    render json: { error: "Failed to scan library: #{e.message}" }, status: :internal_server_error
  end

  private

  def serialize(item)
    case item
    when Movie then MovieSerializer.new(item, params: { user: current_user, request: request }).as_json
    when Episode then EpisodeSerializer.new(item, params: { user: current_user, request: request }).as_json
    when Show then ShowSerializer.new(item, params: { request: request }).as_json
    when Season then SeasonSerializer.new(item, params: { request: request }).as_json
    end
  end
end
