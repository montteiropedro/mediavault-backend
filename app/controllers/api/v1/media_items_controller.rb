class Api::V1::MediaItemsController < ApplicationController
  before_action :set_media_item, only: [:stream_video, :stream_audio, :subtitle]

  def index
    media_items = MediaItem.all.with_attached_cover_art

    render json: media_items.map { |item| media_item_json(item) }
  end

  def stream_video
    file_path = @media_item.file_path

    unless File.exist?(file_path)
      return render json: { error: "File not found on disk" }, status: :not_found
    end

    mime_type = Rack::Mime.mime_type(File.extname(file_path), "video/mp4")

    send_file_with_range_support(file_path, mime_type)
  end

  def stream_audio
    cache = MediaAudioCache.new(@media_item)
    cache.prepare!
    track_index = params[:index].to_i
    cached_track_path = cache.path(track_index)

    unless cache.exist?(track_index)
      result = MediaGenerateAudioService.call(@media_item, track_index, cached_track_path)

      unless result.success
        error = RuntimeError.new(result.stderr.presence || "Error extracting audio (Exit code: #{status.exitstatus})")
        ApplicationLogger.error(error, location: "Api::V1::MediaItemsController")
        return head :not_found
      end
    end

    send_file_with_range_support(cached_track_path, "audio/mp4")
  end

  def subtitle
    cache = MediaSubtitleCache.new(@media_item)
    cache.prepare!

    track_index = params[:index].to_i
    cached_track_path = cache.path(track_index)

    unless cache.exist?(track_index)
      _stdout, stderr, status = MediaGenerateSubtitleService.call(@media_item, track_index, cached_track_path)

      unless status.success?
        error = RuntimeError.new(stderr.presence || "Error extracting subtitles (Exit code: #{status.exitstatus})")
        ApplicationLogger.error(error, location: "Api::V1::MediaItemsController")
        return head :not_found
      end
    end

    # Sends the generated .vtt file with the correct HTTP header required by HTML5.
    send_file(cached_track_path, type: 'text/vtt', disposition: 'inline')
  end

  private

  def media_item_params
    params.require(:media_item).permit(:title, :description, :duration, :media_type, :category_id, metadata: {})
  end

  def set_media_item
    @media_item = MediaItem.find(params[:id] || params[:media_item_id])
  end

  def media_item_json(item)
    metadata = MediaMetadataService.call(item.file_path)

    item.as_json(
      include: { category: { only: [:id, :name] } },
      exclude: [:created_at, :updated_at],
    ).merge(
      cover_art_url: item.cover_art.attached? ? url_for(item.cover_art) : nil,
      video_url: stream_video_api_v1_media_item_url(item),
      audios: item.audio_tracks,
      subtitles: item.subtitle_tracks,
      user_progress_seconds: item.user_progress(User.first)
    )
  end

  def send_file_with_range_support(file_path, mime_type)
    file_size = File.size(file_path)
    range_header = request.headers["Range"]

    unless range_header
      response.headers["Accept-Ranges"] = "bytes"
      return send_file(file_path, type: mime_type, disposition: "inline")
    end

    # Extracts the requested start and end bytes (e.g., "bytes=100-200")
    bytes = range_header.sub(/bytes=/, "").split("-")
    start_byte = bytes[0].to_i
    end_byte = bytes[1].presence ? bytes[1].to_i : [start_byte + 2_000_000 - 1, file_size - 1].min # Chunks of ~2MB
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
  end
end
