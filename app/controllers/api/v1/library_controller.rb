class Api::V1::LibraryController < ApplicationController
  def scan
    result = ScanMediaService.call

    render json: {
      message: "Library scan completed successfully.",
      scanned_count: result[:scanned],
      removed_count: result[:removed]
    }, status: :ok
  rescue StandardError => e
    render json: { error: "Failed to scan library: #{e.message}" }, status: :internal_server_error
  end
end
