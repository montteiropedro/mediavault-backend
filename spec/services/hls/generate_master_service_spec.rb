require "rails_helper"

RSpec.describe Hls::GenerateMasterService do
  describe ".call" do
    let(:playable) do
      instance_double("Episode", audio_tracks: audio_tracks, subtitle_tracks: subtitle_tracks)
    end
    let(:audio_tracks) { [] }
    let(:subtitle_tracks) { [] }

    subject(:result) { described_class.call(playable) }

    context "with a playable that has no tracks" do
      it "generates a basic HLS master playlist with headers and stream info" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-INDEPENDENT-SEGMENTS",
          "#EXT-X-STREAM-INF:BANDWIDTH=5000000,AUDIO=\"audio\",SUBTITLES=\"subtitles\"",
          "video/playlist.m3u8"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "with audio tracks" do
      let(:audio_tracks) do
        [
          { "label" => "English", "language" => "eng" },
          { "label" => "Portuguese", "language" => "por" }
        ]
      end

      it "includes the standard headers and the video stream line" do
        expect(result).to start_with("#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-INDEPENDENT-SEGMENTS")
        expect(result).to end_with("#EXT-X-STREAM-INF:BANDWIDTH=5000000,AUDIO=\"audio\",SUBTITLES=\"subtitles\"\nvideo/playlist.m3u8")
      end

      it "configures the first audio track as the default/autoselect" do
        expected_first_track = '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",LANGUAGE="eng",DEFAULT=YES,AUTOSELECT=YES,URI="audio/0/playlist.m3u8"'
        expect(result).to include(expected_first_track)
      end

      it "configures subsequent audio tracks without default/autoselect" do
        expected_second_track = '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Portuguese",LANGUAGE="por",DEFAULT=NO,AUTOSELECT=NO,URI="audio/1/playlist.m3u8"'
        expect(result).to include(expected_second_track)
      end
    end

    context "with subtitle tracks" do
      let(:subtitle_tracks) do
        [
          { "label" => "English (SRT)", "language" => "eng" },
          { "label" => "Spanish", "language" => "spa" }
        ]
      end

      it "includes the standard headers and the video stream line" do
        expect(result).to start_with("#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-INDEPENDENT-SEGMENTS")
        expect(result).to end_with("#EXT-X-STREAM-INF:BANDWIDTH=5000000,AUDIO=\"audio\",SUBTITLES=\"subtitles\"\nvideo/playlist.m3u8")
      end

      it "configures all subtitle tracks as non-default, non-autoselect, and non-forced" do
        expected_first_sub = '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subtitles",NAME="English (SRT)",LANGUAGE="eng",DEFAULT=NO,AUTOSELECT=NO,FORCED=NO,URI="subtitle/0/playlist.m3u8"'
        expected_second_sub = '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subtitles",NAME="Spanish",LANGUAGE="spa",DEFAULT=NO,AUTOSELECT=NO,FORCED=NO,URI="subtitle/1/playlist.m3u8"'

        expect(result).to include(expected_first_sub)
        expect(result).to include(expected_second_sub)
      end
    end

    context "with both audio and subtitle tracks" do
      let(:audio_tracks) do
        [
          { "label" => "English", "language" => "eng" }
        ]
      end

      let(:subtitle_tracks) do
        [
          { "label" => "Portuguese", "language" => "por" }
        ]
      end

      it "properly structures and orders the master playlist with headers, audio media tags, subtitle media tags, and the stream info at the end" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-INDEPENDENT-SEGMENTS",
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",LANGUAGE="eng",DEFAULT=YES,AUTOSELECT=YES,URI="audio/0/playlist.m3u8"',
          '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subtitles",NAME="Portuguese",LANGUAGE="por",DEFAULT=NO,AUTOSELECT=NO,FORCED=NO,URI="subtitle/0/playlist.m3u8"',
          '#EXT-X-STREAM-INF:BANDWIDTH=5000000,AUDIO="audio",SUBTITLES="subtitles"',
          "video/playlist.m3u8"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end
  end
end
