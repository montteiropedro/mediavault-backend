class Api::V1::StreamingController < ApplicationController
  before_action :set_playable

  def audio
    cache = MediaAudioCache.new(@playable)
    cache.prepare!
    track_index = params[:index].to_i
    cached_track_path = cache.path(track_index)

    unless cache.exist?(track_index)
      result = MediaGenerateAudioService.call(@playable, track_index, cached_track_path)

      unless result.success
        error = RuntimeError.new(result.stderr.presence || "Error extracting audio")
        ApplicationLogger.error(error, location: self.class.name)
        return head :not_found
      end
    end

    send_file_with_range_support(cached_track_path, "audio/mp4")
  end

  def subtitle
    cache = MediaSubtitleCache.new(@playable)
    cache.prepare!

    track_index = params[:index].to_i
    cached_track_path = cache.path(track_index)

    unless cache.exist?(track_index)
      _stdout, stderr, status = MediaGenerateSubtitleService.call(@playable, track_index, cached_track_path)

      unless status.success?
        error = RuntimeError.new(stderr.presence || "Error extracting subtitles")
        ApplicationLogger.error(error, location: self.class.name)
        return head :not_found
      end
    end

    send_file cached_track_path, type: "text/vtt", disposition: "inline"
  end

  def hls_playlist
    cache = Hls::SegmentCache.new(@playable)
    cache.prepare!

    render plain: cache.playlist, content_type: "application/vnd.apple.mpegurl"
  end

  def hls_segment
    cache = Hls::SegmentCache.new(@playable)
    index = params[:index].to_i
    path = cache.path(index)

    Hls::SegmentLock.synchronize(@playable.id, index) do
      unless cache.exist?(index)
        result = Hls::GenerateSegmentService.call(@playable, index, path)

        unless result.success
          ApplicationLogger.error(RuntimeError.new(result.stderr), location: self.class.name)
          return head :not_found
        end
      end
    end

    FileUtils.touch(path)
    send_file path, type: "video/mp2t", disposition: "inline"
  end

  private

  def set_playable
    @playable = Playable.find_playable(params[:id], type: params[:type])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "playable not found" }, status: :not_found
  end

  def send_file_with_range_support(file_path, mime_type)
    file_size = File.size(file_path)
    range_header = request.headers["Range"]

    unless range_header
      response.headers["Accept-Ranges"] = "bytes"
      return send_file file_path, type: mime_type, disposition: "inline"
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

    # Reads only the requested portion of the file.
    File.open(file_path, "rb") do |file|
      file.seek(start_byte)
      chunk = file.read(length)
      send_data chunk, type: mime_type, disposition: "inline", status: 206
    end
  end
end
