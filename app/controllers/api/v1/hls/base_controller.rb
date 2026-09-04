class Api::V1::Hls::BaseController < ApplicationController
  before_action :set_playable

  def hls_master
    playlist = Hls::GenerateMasterService.call(@playable)

    render plain: playlist, content_type: "application/vnd.apple.mpegurl"
  end

  def hls_video_playlist
    Hls::VideoCache.new(@playable).prepare!
    playlist = Hls::GeneratePlaylistService.call(@playable)

    render plain: playlist, content_type: "application/vnd.apple.mpegurl"
  end

  def hls_video_segment
    cache = Hls::VideoCache.new(@playable)
    segment_index = params[:segment_index].to_i
    path = cache.path(segment_index)

    Hls::SegmentLock.synchronize(@playable.id, "video", segment_index) do
      unless cache.exist?(segment_index)
        result = Hls::GenerateVideoSegmentService.call(@playable, segment_index, path)

        unless result.success
          ApplicationLogger.error(RuntimeError.new(result.stderr), location: self.class.name)
          return head :not_found
        end
      end
    end

    FileUtils.touch(path)
    send_file path, type: "video/mp2t", disposition: "inline"
  end

  def hls_audio_playlist
    track_index = params[:track_index].to_i
    Hls::AudioCache.new(@playable, track_index).prepare!
    playlist = Hls::GeneratePlaylistService.call(@playable)

    render plain: playlist, content_type: "application/vnd.apple.mpegurl"
  end

  def hls_audio_segment
    track_index = params[:track_index].to_i
    segment_index = params[:segment_index].to_i

    cache = Hls::AudioCache.new(@playable, track_index)
    cache.prepare!

    path = cache.path(segment_index)

    Hls::SegmentLock.synchronize(@playable.id, "audio-#{track_index}", segment_index) do
      unless cache.exist?(segment_index)
        result = Hls::GenerateAudioSegmentService.call(
          @playable,
          track_index,
          segment_index,
          path
        )

        unless result.success
          ApplicationLogger.error(RuntimeError.new(result.stderr), location: self.class.name)
          return head :not_found
        end
      end
    end

    FileUtils.touch(path)
    send_file path, type: "video/mp2t", disposition: "inline"
  end

  def hls_subtitle_playlist
    track_index = params[:track_index].to_i
    Hls::SubtitleCache.new(@playable).prepare!
    playlist = Hls::GenerateSubtitlePlaylistService.call(@playable, track_index)

    render plain: playlist, content_type: "application/vnd.apple.mpegurl"
  end

  def hls_subtitle
    track_index = params[:track_index].to_i
    cache = Hls::SubtitleCache.new(@playable)
    path = cache.path(track_index)

    Hls::SegmentLock.synchronize(@playable.id, "subtitle", track_index) do
      unless cache.exist?(track_index)
        result = Hls::GenerateSubtitleService.call(@playable, track_index, path)

        unless result.success
          ApplicationLogger.error(RuntimeError.new(result.stderr), location: self.class.name)
          return head :not_found
        end
      end
    end

    FileUtils.touch(path)
    send_file path, type: "text/vtt", disposition: "inline"
  end

  private

  def set_playable
    raise NotImplementedError
  end
end
