require "rails_helper"

RSpec.describe MediaSubtitleCache do
  let(:media_item) { instance_double("MediaItem", id: 123) }
  let(:cache) { described_class.new(media_item, root: @tmp_dir) }

  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  describe "#exist?" do
    before { cache.prepare! }

    it "returns false when the track does not exist" do
      expect(cache.exist?(1)).to be(false)
    end

    it "returns true when the track exists" do
      FileUtils.touch(@tmp_dir.join("tmp", "subtitles", "123", "track_1.vtt"))

      expect(cache.exist?(1)).to be(true)
    end
  end

  describe "#path" do
    it "returns the expected subtitle path" do
      expect(cache.path(1)).to eq(@tmp_dir.join("tmp", "subtitles", "123", "track_1.vtt"))
    end
  end

  describe "#prepare!" do
    it "creates the cache directory" do
      expect { cache.prepare! }
        .to change { File.directory?(@tmp_dir.join("tmp", "subtitles", "123")) }
        .from(false)
        .to(true)
    end
  end
end
