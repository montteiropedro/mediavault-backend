class Hls::GenerateMasterService
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
      "#EXT-X-INDEPENDENT-SEGMENTS"
    ]

    @playable.audio_tracks.each_with_index do |track, index|
      lines << audio_media_tag(track, index)
    end

    @playable.subtitle_tracks.each_with_index do |track, index|
      lines << subtitle_media_tag(track, index)
    end

    lines << "#EXT-X-STREAM-INF:BANDWIDTH=5000000,AUDIO=\"audio\",SUBTITLES=\"subtitles\""
    lines << "video/playlist.m3u8"

    lines.join("\n")
  end

  private

  def audio_media_tag(track, index)
    default = index.zero? ? "YES" : "NO"

    [
      "#EXT-X-MEDIA:TYPE=AUDIO",
      "GROUP-ID=\"audio\"",
      "NAME=\"#{track['label']}\"",
      "LANGUAGE=\"#{track['language']}\"",
      "DEFAULT=#{default}",
      "AUTOSELECT=#{default}",
      "URI=\"audio/#{index}/playlist.m3u8\""
    ].join(",")
  end

  def subtitle_media_tag(track, index)
      [
        "#EXT-X-MEDIA:TYPE=SUBTITLES",
        "GROUP-ID=\"subtitles\"",
        "NAME=\"#{track['label']}\"",
        "LANGUAGE=\"#{track['language']}\"",
        "DEFAULT=NO",
        "AUTOSELECT=NO",
        "FORCED=NO",
        "URI=\"subtitle/#{index}/playlist.m3u8\""
      ].join(",")
    end
end
