require "rails_helper"

RSpec.describe Hls::VideoCache do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  let(:playable) { instance_double("Movie", id: 123) }
  let(:cache) { described_class.new(playable, base_dir: @tmp_dir) }

  describe "#path" do
    it "returns the expected path of the segment with 3-digit formatting." do
      expect(cache.path(5)).to eq(@tmp_dir.join("123", "video", "segment005.ts"))
    end
  end

  describe "#exist?" do
    before { cache.prepare! }

    it "returns false when the segment file has not been created" do
      expect(cache.exist?(0)).to be(false)
    end

    it "returns true when the segment file exists" do
      FileUtils.touch(@tmp_dir.join("123", "video", "segment001.ts"))

      expect(cache.exist?(1)).to be(true)
    end
  end

  describe "#prepare!" do
    it "creates the cache directory" do
      expected_dir = @tmp_dir.join("123")

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
