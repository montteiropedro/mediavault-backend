require "rails_helper"

RSpec.describe Hls::GenerateSubtitlePlaylistService do
  describe ".call" do
    subject(:result) { described_class.call(playable, track_index) }

    let(:track_index) { 0 }

    context "with a duration that has no fractional part" do
      let(:playable) { instance_double("Episode", duration_seconds: 12) }

      it "builds the playlist with matching target duration and EXTINF" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:12",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:12.0,",
          "../000.vtt",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "with a fractional duration" do
      let(:playable) { instance_double("Episode", duration_seconds: 12.4) }

      it "rounds TARGETDURATION up and keeps EXTINF precise" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:13",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:12.4,",
          "../000.vtt",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "with a duration that needs rounding to three decimal places" do
      let(:playable) { instance_double("Episode", duration_seconds: 12.34567) }

      it "rounds EXTINF to three decimal places" do
        expect(result).to include("#EXTINF:12.346,")
      end
    end

    context "with track_index greater than zero" do
      let(:playable) { instance_double("Episode", duration_seconds: 10) }
      let(:track_index) { 7 }

      it "pads the subtitle filename with leading zeros" do
        expect(result).to include("../007.vtt")
      end
    end

    context "with a track_index requiring three digits" do
      let(:playable) { instance_double("Episode", duration_seconds: 10) }
      let(:track_index) { 123 }

      it "keeps the three-digit format without truncation" do
        expect(result).to include("../123.vtt")
      end
    end

    context "with a zero duration" do
      let(:playable) { instance_double("Episode", duration_seconds: 0) }

      it "generates a playlist with zeroed target duration and EXTINF" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:0",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:0.0,",
          "../000.vtt",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end
  end
end
