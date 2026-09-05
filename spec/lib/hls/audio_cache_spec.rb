require "rails_helper"

RSpec.describe Hls::AudioCache do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  let(:playable) { instance_double("Episode", id: 123) }
  let(:track_index) { 0 }
  let(:cache) { described_class.new(playable, track_index, base_dir: @tmp_dir) }

  describe "#path" do
    it "builds the segment path using playable id, 'audio', and track_index" do
      expected_path = @tmp_dir.join("123", "audio", "0", "segment005.ts")

      expect(cache.path(5)).to eq(expected_path)
    end

    it "pads the segment index with leading zeros" do
      expect(cache.path(7).basename.to_s).to eq("segment007.ts")
    end

    it "does not truncate segment indexes with three or more digits" do
      expect(cache.path(123).basename.to_s).to eq("segment123.ts")
    end

    context "with a different track_index" do
      let(:track_index) { 2 }

      it "includes the track_index in the cache directory" do
        expect(cache.path(0).to_s).to include(File.join("123", "audio", "2"))
      end
    end
  end

  describe "#exist?" do
    before { cache.prepare! }

    it "returns false when the segment file has not been created" do
      expect(cache.exist?(0)).to be(false)
    end

    it "returns true when the segment file exists" do
      FileUtils.touch(@tmp_dir.join("123", "audio", "0", "segment001.ts"))

      expect(cache.exist?(1)).to be(true)
    end
  end

  describe "#prepare!" do
    it "creates the cache directory" do
      expected_dir = @tmp_dir.join("123", "audio", "0")

      expect { cache.prepare! }
        .to change { File.directory?(expected_dir) }
        .from(false)
        .to(true)
    end

    it "is idempotent when called multiple times" do
      cache.prepare!

      expect { cache.prepare! }.not_to raise_error
    end
  end
end
