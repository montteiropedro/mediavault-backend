class Api::V1::LibraryController < ApplicationController
  def scan
    MediaLibraryScanJob.perform_later

    render status: :ok
  rescue StandardError => e
    render json: { error: "Failed to scan library: #{e.message}" }, status: :internal_server_error
  end
end
