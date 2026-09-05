require "rails_helper"

RSpec.describe Hls::CleanCacheJob, type: :job do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  before { stub_const("Hls::Base::DEFAULT_BASE_DIR", @tmp_dir) }

  describe "#perform" do
    context "when the cache base directory does not exist" do
      let(:missing_base_dir) { @tmp_dir.join("non_existent") }

      before { stub_const("Hls::Base::DEFAULT_BASE_DIR", missing_base_dir) }

      it "logs an info message and returns early" do
        expect(ApplicationLogger).to receive(:info).with(
          "cache_base_dir not found",
          location: "Hls::CleanCacheJob"
        )

        expect { described_class.new.perform }.not_to(raise_error)
      end
    end

    context "when the cache base directory exists" do
      let(:playable_dir_1) { @tmp_dir.join("playable_1") }
      let(:playable_dir_2) { @tmp_dir.join("playable_2") }

      before do
        video_dir_1 = playable_dir_1.join("video")
        audio_dir_1 = playable_dir_1.join("audio", "1")
        subtitles_dir_1 = playable_dir_1.join("subtitles")
        FileUtils.mkdir_p([video_dir_1, audio_dir_1, subtitles_dir_1])

        @fresh_video = video_dir_1.join("segment001.ts")
        File.write(@fresh_video, "Fresh video content")

        @expired_audio = audio_dir_1.join("segment001.ts")
        File.write(@expired_audio, "Expired audio content")
        backdated_time = 25.hours.ago.to_time
        File.utime(backdated_time, backdated_time, @expired_audio)

        @expired_subtitle = subtitles_dir_1.join("000.vtt")
        File.write(@expired_subtitle, "Expired subtitle content")
        File.utime(backdated_time, backdated_time, @expired_subtitle)

        video_dir_2 = playable_dir_2.join("video")
        FileUtils.mkdir_p(video_dir_2)

        @expired_video_2 = video_dir_2.join("segment001.ts")
        File.write(@expired_video_2, "Expired video content folder 2")
        File.utime(backdated_time, backdated_time, @expired_video_2)
      end

      it "deletes video segments, audio segments, and subtitles older than retention period" do
        described_class.new.perform

        expect(File.exist?(@fresh_video)).to be(true)
        expect(File.exist?(@expired_audio)).to be(false)
        expect(File.exist?(@expired_subtitle)).to be(false)
        expect(File.exist?(@expired_video_2)).to be(false)
      end

      it "removes empty directories recursively under the cache folder" do
        described_class.new.perform

        expect(Dir.exist?(playable_dir_2)).to be(false)
      end

      it "keeps non-empty directories under the cache folder" do
        described_class.new.perform

        expect(Dir.exist?(playable_dir_1)).to be(true)
      end

      context "when an error occurs during file deletion" do
        it "rescues the error and logs a warning" do
          allow(File).to receive(:delete).and_call_original
          allow(File).to receive(:delete).with(@expired_audio.to_s).and_raise(StandardError, "Failed to delete file")

          expect(ApplicationLogger).to receive(:warn).with(
            a_string_including("Failed to delete file"),
            location: "Hls::CleanCacheJob",
            context: { file_path: @expired_audio.to_s }
          )

          described_class.new.perform
          expect(File.exist?(@expired_subtitle)).to be(false)
        end
      end

      context "when an error occurs during empty directory removal" do
        it "rescues the error and logs a warning" do
          File.delete(@expired_video_2)

          allow(Dir).to receive(:rmdir).and_call_original
          allow(Dir).to receive(:rmdir).with(playable_dir_2.to_s).and_raise(StandardError, "Failed to delete directory")

          expect(ApplicationLogger).to receive(:warn).with(
            a_string_including("Failed to delete directory"),
            location: "Hls::CleanCacheJob",
            context: hash_including(:dir)
          )

          described_class.new.perform
        end
      end
    end
  end
end
