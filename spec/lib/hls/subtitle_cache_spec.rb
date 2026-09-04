require "rails_helper"

RSpec.describe Hls::SubtitleCache do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  let(:playable) { instance_double("Episode", id: 123) }
  let(:cache) { described_class.new(playable, base_dir: @tmp_dir) }

  describe "#path" do
    it "builds the vtt path using playable id and 'subtitles'" do
      expected_path = @tmp_dir.join("123", "subtitles", "005.vtt")

      expect(cache.path(5)).to eq(expected_path)
    end

    it "pads the vtt index with leading zeros" do
      expect(cache.path(7).basename.to_s).to eq("007.vtt")
    end

    it "does not truncate segment indexes with three or more digits" do
      expect(cache.path(123).basename.to_s).to eq("123.vtt")
    end
  end

  describe "#exist?" do
    before { cache.prepare! }

    it "returns false when the vtt file has not been created" do
      expect(cache.exist?(0)).to be(false)
    end

    it "returns true when the vtt file exists" do
      FileUtils.touch(@tmp_dir.join("123", "subtitles", "001.vtt"))

      expect(cache.exist?(1)).to be(true)
    end
  end

  describe "#prepare!" do
    it "creates the cache directory" do
      expected_dir = @tmp_dir.join("123", "subtitles")

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
