require "rails_helper"

RSpec.describe MediaGenerateAudioService do
  let(:media_item) { instance_double("MediaItem", file_path: "/path/to/movie.mp4") }
  let(:track_index) { 1 }
  let(:output_path) { Pathname.new("/tmp/audios/audio_track_1.m4a") }

  describe ".call" do
    let(:ffprobe_status) { instance_double(Process::Status, success?: true) }
    let(:ffmpeg_status) { instance_double(Process::Status, success?: true) }

    let(:ffprobe_command) do
      [
        "ffprobe",
        "-v", "error",
        "-print_format", "csv=p=0",
        "-select_streams", "a:1",
        "-show_entries", "stream=codec_name,channels,channel_layout",
        "/path/to/movie.mp4"
      ]
    end

    context "when the audio codec is browser-compatible (e.g., aac)" do
      it "copies the stream without re-encoding" do
        expect(Open3).to receive(:capture3)
          .with(*ffprobe_command)
          .and_return(["aac\n", "", ffprobe_status])

        expect(Open3).to receive(:capture3).with(
          "ffmpeg",
          "-y",
          "-v", "error",
          "-i", "/path/to/movie.mp4",
          "-map", "0:a:1",
          "-c:a", "copy",
          "-f", "mp4",
          "/tmp/audios/audio_track_1.m4a"
        ).and_return(["", "", ffmpeg_status])

        result = described_class.call(media_item, track_index, output_path)

        expect(result).to be_an_instance_of(described_class::Result)
        expect(result.success).to be(true)
        expect(result.stderr).to eq("")
      end
    end

    context "when the audio codec is not browser-compatible (e.g., dts)" do
      it "re-encodes the stream to aac at 192k" do
        expect(Open3).to receive(:capture3)
          .with(*ffprobe_command)
          .and_return(["dts\n", "", ffprobe_status])

        expect(Open3).to receive(:capture3).with(
          "ffmpeg",
          "-y",
          "-v", "error",
          "-i", "/path/to/movie.mp4",
          "-map", "0:a:1",
          "-c:a", "aac",
          "-b:a", "192k",
          "-ac", "1",
          "-channel_layout", "mono",
          "-f", "mp4",
          "/tmp/audios/audio_track_1.m4a"
        ).and_return(["", "", ffmpeg_status])

        result = described_class.call(media_item, track_index, output_path)

        expect(result).to be_an_instance_of(described_class::Result)
        expect(result.success).to be(true)
        expect(result.stderr).to eq("")
      end
    end

    context "when the ffprobe command fails" do
      let(:ffprobe_status) { instance_double(Process::Status, success?: false) }

      it "falls back safely to re-encoding instead of breaking" do
        expect(Open3).to receive(:capture3)
          .with(*ffprobe_command)
          .and_return(["", "ffprobe stderr", ffprobe_status])

        expect(Open3).to receive(:capture3).with(
          "ffmpeg",
          "-y",
          "-v", "error",
          "-i", "/path/to/movie.mp4",
          "-map", "0:a:1",
          "-c:a", "aac",
          "-b:a", "192k",
          "-ac", "1",
          "-channel_layout", "mono",
          "-f", "mp4",
          "/tmp/audios/audio_track_1.m4a"
        ).and_return(["", "", ffmpeg_status])

        result = described_class.call(media_item, track_index, output_path)

        expect(result).to be_an_instance_of(described_class::Result)
        expect(result.success).to be(true)
      end
    end

    context "when the ffmpeg command fails" do
      let(:ffmpeg_status) { instance_double(Process::Status, success?: false) }

      it "returns failure and captures stderr from the ffmpeg output" do
        expect(Open3).to receive(:capture3)
          .with(*ffprobe_command)
          .and_return(["aac\n", "", ffprobe_status])

        expect(Open3).to receive(:capture3).with(
          "ffmpeg",
          "-y",
          "-v", "error",
          "-i", "/path/to/movie.mp4",
          "-map", "0:a:1",
          "-c:a", "copy",
          "-f", "mp4",
          "/tmp/audios/audio_track_1.m4a"
        ).and_return(["", "ffmpeg stderr", ffmpeg_status])

        result = described_class.call(media_item, track_index, output_path)

        expect(result).to be_an_instance_of(described_class::Result)
        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg stderr")
      end
    end
  end
end
