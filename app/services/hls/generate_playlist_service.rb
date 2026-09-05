class Hls::GeneratePlaylistService
  def self.call(playable)
    new(playable).call
  end

  def initialize(playable)
    @playable = playable
  end

  def call
    lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:3",
      "#EXT-X-TARGETDURATION:#{Hls::Base::SEGMENT_DURATION_IN_SECONDS}",
      "#EXT-X-MEDIA-SEQUENCE:0"
    ]

    total_segments.times do |index|
      duration = segment_duration(index)

      lines << "#EXTINF:#{duration},"
      lines << "%03d.ts" % index
    end

    lines << "#EXT-X-ENDLIST"
    lines.join("\n")
  end

  private

  def total_segments
    duration = @playable.duration_seconds.to_f
    (duration / Hls::Base::SEGMENT_DURATION_IN_SECONDS).ceil
  end

  def segment_duration(index)
    duration = @playable.duration_seconds.to_f
    remaining = duration - (index * Hls::Base::SEGMENT_DURATION_IN_SECONDS)

    [remaining, Hls::Base::SEGMENT_DURATION_IN_SECONDS.to_f].min.round(3)
  end
end
