class Hls::GenerateSubtitlePlaylistService
  def self.call(playable, track_index)
    new(playable, track_index).call
  end

  def initialize(playable, track_index)
    @playable = playable
    @track_index = track_index
  end

  def call
    [
      "#EXTM3U",
      "#EXT-X-VERSION:3",
      "#EXT-X-TARGETDURATION:#{target_duration}",
      "#EXT-X-MEDIA-SEQUENCE:0",
      "#EXTINF:#{duration},",
      "../%03d.vtt" % @track_index,
      "#EXT-X-ENDLIST"
    ].join("\n")
  end

  private

  def duration
    @playable.duration_seconds.to_f.round(3)
  end

  def target_duration
    @playable.duration_seconds.to_f.ceil
  end
end
