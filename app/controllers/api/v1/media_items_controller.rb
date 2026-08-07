class Api::V1::MediaItemsController < ApplicationController
  before_action :set_media_item, only: [:stream]

  def index
    @media_items = MediaItem.all.with_attached_cover_art

    render json: @media_items.map { |item| media_item_json(item) }
  end

  def stream
    file_path = @media_item.file_path

    unless File.exist?(file_path)
      return render json: { error: "File not found on disk" }, status: :not_found
    end

    file_size = File.size(file_path)
    # Find out the MIME type of the file (video/mp4, video/mkv, etc.)
    mime_type = Rack::Mime.mime_type(File.extname(file_path), "video/mp4")

    # Checks if the browser sent the 'Range' header requesting a segment of the video.
    range_header = request.headers["Range"]

    if range_header
      # Extracts the requested start and end bytes (e.g., "bytes=100-200")
      bytes = range_header.sub(/bytes=/, "").split("-")

      start_byte = bytes[0].to_i
      end_byte = bytes[1] ? bytes[1].to_i : [start_byte + 2_000_000 - 1, file_size - 1].min # Chunks of ~2MB

      length = end_byte - start_byte + 1

      # Defines the HTTP 206 Partial Content response headers.
      response.headers["Content-Range"] = "bytes #{start_byte}-#{end_byte}/#{file_size}"
      response.headers["Accept-Ranges"] = "bytes"
      response.headers["Content-Length"] = length.to_s
      response.headers["Content-Type"] = mime_type

      # Reads only the requested portion of the file.
      File.open(file_path, "rb") do |file|
        file.seek(start_byte)
        chunk = file.read(length)
        send_data chunk, type: mime_type, disposition: "inline", status: 206
      end
    else
      # Standard full download/view request
      # send_file streams the file in chunks (supporting pause, seek, and range requests).
      response.headers["Accept-Ranges"] = "bytes"
      send_file file_path, type: mime_type, disposition: "inline"
    end
  end

  private

  def media_item_params
    params.require(:media_item).permit(:title, :description, :duration, :media_type, :category_id, metadata: {})
  end

  def set_media_item
    @media_item = MediaItem.find(params[:id])
  end

  def media_item_json(item)
    item.as_json(
      include: { category: { only: [:id, :name] } },
      exclude: [:created_at, :updated_at],
    ).merge(
      cover_art_url: item.cover_art.attached? ? url_for(item.cover_art) : nil,
      video_url: stream_api_v1_media_item_url(item, host: "http://localhost:#{ENV['PORT']}"),
      user_progress_seconds: item.user_progress(User.first)
    )
  end
end
