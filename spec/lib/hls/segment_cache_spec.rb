require "rails_helper"

RSpec.describe Hls::SegmentCache do
  let(:playable) { instance_double("Movie", id: 123, duration_seconds: 1000) }
  let(:cache) { described_class.new(playable, base_dir: @tmp_dir) }

  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  describe "#exist?" do
    before { cache.prepare! }

    it "returns false when the segment does not exist" do
      expect(cache.exist?(1)).to be(false)
    end

    it "returns true when the segment exists" do
      FileUtils.touch(@tmp_dir.join("123", "segment001.ts"))

      expect(cache.exist?(1)).to be(true)
    end
  end

  describe "#path" do
    it "returns the expected path of the segment with 3-digit formatting." do
      expect(cache.path(5)).to eq(@tmp_dir.join("123", "segment005.ts"))
    end
  end

  describe "#prepare!" do
    it "creates the cache directory corresponding to the media ID" do
      expect { cache.prepare! }
        .to change { File.directory?(@tmp_dir.join("123")) }
        .from(false)
        .to(true)
    end
  end

  describe "#playlist" do
    context "when the video duration is not a multiple of the 6 seconds segment duration (e.g., 15s)" do
      let(:playable) { instance_double("Movie", id: 123, duration_seconds: 15) }

      it "calculates 3 segments and generates the correct HLS m3u8 playlist" do
        expected_playlist = <<~M3U8.strip
          #EXTM3U
          #EXT-X-VERSION:3
          #EXT-X-TARGETDURATION:6
          #EXT-X-MEDIA-SEQUENCE:0
          #EXTINF:6.0,
          000.ts
          #EXTINF:6.0,
          001.ts
          #EXTINF:6.0,
          002.ts
          #EXT-X-ENDLIST
        M3U8

        expect(cache.playlist).to eq(expected_playlist)
      end
    end

    context "when the duration is exactly a multiple of the 6 seconds segment duration (e.g., 12s)" do
      let(:playable) { instance_double("Movie", id: 123, duration_seconds: 12) }

      it "calculates exactly 2 segments" do
        expected_playlist = <<~M3U8.strip
          #EXTM3U
          #EXT-X-VERSION:3
          #EXT-X-TARGETDURATION:6
          #EXT-X-MEDIA-SEQUENCE:0
          #EXTINF:6.0,
          000.ts
          #EXTINF:6.0,
          001.ts
          #EXT-X-ENDLIST
        M3U8

        expect(cache.playlist).to eq(expected_playlist)
      end
    end

    context "when the duration is very short (e.g., 2s)" do
      let(:playable) { instance_double("Movie", id: 123, duration_seconds: 2) }

      it "calculates only 1 segment" do
        expect(cache.playlist).to include("000.ts")
        expect(cache.playlist).not_to include("001.ts")
      end
    end
  end
end
