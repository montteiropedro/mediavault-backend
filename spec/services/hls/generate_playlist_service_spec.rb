require "rails_helper"

RSpec.describe Hls::GeneratePlaylistService do
  describe ".call" do
    subject(:result) { described_class.call(playable) }

    context "when duration divides evenly into segments" do
      let(:playable) { instance_double("Episode", duration_seconds: 12) }

      it "generates the expected number of segments with consistent formatting" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:6",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:6.0,",
          "000.ts",
          "#EXTINF:6.0,",
          "001.ts",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "when duration has a remainder shorter than a full segment" do
      let(:playable) { instance_double("Episode", duration_seconds: 14) }

      it "rounds up the total segment count and shortens the last segment" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:6",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:6.0,",
          "000.ts",
          "#EXTINF:6.0,",
          "001.ts",
          "#EXTINF:2.0,",
          "002.ts",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "when duration is shorter than a single segment" do
      let(:playable) { instance_double("Episode", duration_seconds: 3.5) }

      it "generates a single short segment" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:6",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXTINF:3.5,",
          "000.ts",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end

    context "when duration has a fractional remainder" do
      let(:playable) { instance_double("Episode", duration_seconds: 13.25) }

      it "keeps the fractional precision on the last segment" do
        expect(result).to include("#EXTINF:1.25,")
        expect(result).to end_with("#EXTINF:1.25,\n002.ts\n#EXT-X-ENDLIST")
      end
    end

    context "when duration is zero" do
      let(:playable) { instance_double("Episode", duration_seconds: 0) }

      it "generates a playlist with no segments" do
        expected_playlist = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-TARGETDURATION:6",
          "#EXT-X-MEDIA-SEQUENCE:0",
          "#EXT-X-ENDLIST"
        ].join("\n")

        expect(result).to eq(expected_playlist)
      end
    end
  end
end
