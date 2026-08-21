require "rails_helper"

RSpec.describe Hls::CleanSegmentCacheJob, type: :job do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  before { stub_const("Hls::SegmentCache::DEFAULT_BASE_DIR", @tmp_dir) }

  describe "#perform" do
    context "when the cache base directory does not exist" do
      let(:missing_base_dir) { @tmp_dir.join("non_existent") }

      before { stub_const("Hls::SegmentCache::DEFAULT_BASE_DIR", missing_base_dir) }

      it "logs an info message and returns early" do
        expect(ApplicationLogger).to receive(:info).with(
          "cache_base_dir not found",
          location: "Hls::CleanSegmentCacheJob"
        )

        expect { described_class.new.perform }.not_to(raise_error)
      end
    end

    context "when the cache base directory exists" do
      let(:media_dir_1) { @tmp_dir.join("media_1") }
      let(:media_dir_2) { @tmp_dir.join("media_2") }

      before do
        FileUtils.mkdir_p(media_dir_1)
        FileUtils.mkdir_p(media_dir_2)

        @fresh_file = media_dir_1.join("segment001.ts")
        File.write(@fresh_file, "Now, fresh content folder 1")

        @expired_file_1 = media_dir_1.join("segment002.ts")
        File.write(@expired_file_1, "25 hours ago, expired content folder 1")
        backdated_time = 25.hours.ago.to_time
        File.utime(backdated_time, backdated_time, @expired_file_1)

        @expired_file_2 = media_dir_2.join("segment001.ts")
        File.write(@expired_file_2, "30 hours ago, expired content folder 2")
        backdated_time_2 = 30.hours.ago.to_time
        File.utime(backdated_time_2, backdated_time_2, @expired_file_2)
      end

      it "deletes segments older than the retention period and keeps fresh ones" do
        described_class.new.perform

        expect(File.exist?(@fresh_file)).to be(true)
        expect(File.exist?(@expired_file_1)).to be(false)
        expect(File.exist?(@expired_file_2)).to be(false)
      end

      it "removes empty directories under the cache folder but keeps non-empty ones" do
        described_class.new.perform

        expect(Dir.exist?(media_dir_2)).to be(false)
        expect(Dir.exist?(media_dir_1)).to be(true)
      end

      context "when an error occurs during file deletion" do
        it "rescues the error and logs a warning" do
          allow(File).to receive(:delete).and_call_original
          allow(File).to receive(:delete).with(@expired_file_1.to_s).and_raise(StandardError, "Failed to delete file")

          expect(ApplicationLogger).to receive(:warn).with(
            a_string_including("Failed to delete file"),
            location: "Hls::CleanSegmentCacheJob",
            context: { file_path: @expired_file_1.to_s }
          )

          described_class.new.perform
          expect(File.exist?(@expired_file_2)).to be(false)
        end
      end

      context "when an error occurs during empty directory removal" do
        it "rescues the error and logs a warning" do
          File.delete(@expired_file_2)

          allow(Dir).to receive(:rmdir).and_call_original
          allow(Dir).to receive(:rmdir).with(media_dir_2.to_s).and_raise(StandardError, "Failed to delete directory")

          expect(ApplicationLogger).to receive(:warn).with(
            a_string_including("Failed to delete directory"),
            location: "Hls::CleanSegmentCacheJob",
            context: { dir: media_dir_2.to_s }
          )

          described_class.new.perform
        end
      end
    end
  end
end
