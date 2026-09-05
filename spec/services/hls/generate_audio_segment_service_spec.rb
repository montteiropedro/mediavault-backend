require "rails_helper"

RSpec.describe Hls::GenerateAudioSegmentService do
  let(:playable) { instance_double("Episode", file_path: "path/to/episode.mp4") }
  let(:output_path) { @tmp_dir.join("segment002.ts").to_s }

  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  describe ".call" do
    context "when ffmpeg execution is successful" do
      it "calls ffmpeg with the correct arguments based on the segment index" do
        expect(Open3).to receive(:capture3).with(
          "ffmpeg", "-y",
          "-ss", "12",
          "-i", "path/to/episode.mp4",
          "-t", "6",
          "-map", "0:a:0",
          "-c:a", "aac",
          "-b:a", "192k",
          "-ac", "2",
          "-output_ts_offset", "12",
          "-muxdelay", "0",
          "-f", "mpegts",
          instance_of(String)
        ) do |*args|
          tmp_path = args.last
          File.write(tmp_path, "fake MPEG-TS segment content")
          ["", "ffmpeg success", instance_double(Process::Status, success?: true)]
        end

        result = described_class.call(playable, 0, 2, output_path)

        expect(result.success).to be(true)
        expect(result.stderr).to eq("ffmpeg success")
        expect(File.exist?(output_path)).to be(true)
        expect(File.read(output_path)).to eq("fake MPEG-TS segment content")
      end

      it "fails and cleans up if the generated segment file is empty (0 bytes)" do
        allow(Open3).to receive(:capture3) do |*args|
          tmp_path = args.last
          File.write(tmp_path, "")
          ["", "ffmpeg output was empty", instance_double(Process::Status, success?: true)]
        end

        result = described_class.call(playable, 0, 2, output_path)

        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg output was empty")
        expect(File.exist?(output_path)).to be(false)
      end
    end

    context "when ffmpeg execution fails" do
      it "returns a failed result and cleans up the temporary file if it was created" do
        allow(Open3).to receive(:capture3) do |*args|
          tmp_path = args.last
          File.write(tmp_path, "corrupted partial content")
          ["", "ffmpeg conversion failed", instance_double(Process::Status, success?: false)]
        end

        result = described_class.call(playable, 0, 2, output_path)

        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg conversion failed")
        expect(File.exist?(output_path)).to be(false)
        expect(Dir.glob("#{@tmp_dir}/*")).to be_empty
      end

      it "handles unexpected failures with empty stderr gracefully" do
        allow(Open3).to receive(:capture3) do |*args|
          ["", "", instance_double(Process::Status, success?: false)]
        end

        result = described_class.call(playable, 0, 2, output_path)

        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg failed or produced empty audio file")
      end
    end
  end
end
