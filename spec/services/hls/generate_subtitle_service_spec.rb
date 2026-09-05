require "rails_helper"

RSpec.describe Hls::GenerateSubtitleService do
  let(:playable) { instance_double("Episode", file_path: "path/to/episode.mkv") }
  let(:output_path) { @tmp_dir.join("000.vtt").to_s }

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
          "-v", "error",
          "-i", "path/to/episode.mkv",
          "-map", "0:s:0",
          "-f", "webvtt",
          instance_of(String)
        ) do |*args|
          tmp_path = args.last
          File.write(tmp_path, "fake webvtt content")
          ["", "ffmpeg success", instance_double(Process::Status, success?: true)]
        end

        result = described_class.call(playable, 0, output_path)

        expect(result.success).to be(true)
        expect(result.stderr).to eq("ffmpeg success")
        expect(File.exist?(output_path)).to be(true)
        expect(File.read(output_path)).to eq("fake webvtt content")
      end

      it "fails and cleans up if the generated segment file is empty (0 bytes)" do
        allow(Open3).to receive(:capture3) do |*args|
          tmp_path = args.last
          File.write(tmp_path, "")
          ["", "ffmpeg output was empty", instance_double(Process::Status, success?: true)]
        end

        result = described_class.call(playable, 0, output_path)

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

        result = described_class.call(playable, 0, output_path)

        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg conversion failed")
        expect(File.exist?(output_path)).to be(false)
        expect(Dir.glob("#{@tmp_dir}/*")).to be_empty
      end

      it "handles unexpected failures with empty stderr gracefully" do
        allow(Open3).to receive(:capture3) do |*args|
          ["", "", instance_double(Process::Status, success?: false)]
        end

        result = described_class.call(playable, 0, output_path)

        expect(result.success).to be(false)
        expect(result.stderr).to eq("ffmpeg failed or produced empty subtitle file")
      end
    end
  end

  describe "#sanitize_vtt (private, tested via .call)" do
    let(:status) { instance_double(Process::Status, success?: true) }

    subject(:result) { described_class.call(playable, 0, output_path) }

    before do
      allow(Open3).to receive(:capture3).and_return(["", "", status])
      allow(File).to receive(:exist?).with(output_path).and_return(true)
      allow(File).to receive(:size).with(output_path).and_return(1)
      allow(File).to receive(:read).with(output_path).and_return(raw_content)
      allow(File).to receive(:write)
    end

    context "with conversion artifacts like {=1}" do
      let(:raw_content) { "Hello {=1}world{=2}!" }

      it "strips the conversion artifact markers" do
        result
        expect(File).to have_received(:write).with(output_path, "Hello world!")
      end
    end

    context "with formatting VTT tags" do
      let(:raw_content) { "<b>Bold</b> and <i>italic</i> text" }

      it "strips formatting tags while keeping the text content" do
        result
        expect(File).to have_received(:write).with(output_path, "Bold and italic text")
      end
    end

    context "with voice and timestamp tags" do
      let(:raw_content) { %(<v voice="Speaker">Hi</v> <00:00:01.000>there) }

      it "strips voice and karaoke timestamp tags" do
        result
        expect(File).to have_received(:write).with(output_path, "Hi there")
      end
    end

    context "with ruby/rt tags" do
      let(:raw_content) { "<ruby>Some<rt>thing</rt></ruby>" }

      it "strips ruby annotation tags" do
        result
        expect(File).to have_received(:write).with(output_path, "Something")
      end
    end

    context "with plain text and no tags" do
      let(:raw_content) { "Just plain subtitle text" }

      it "leaves the content unchanged" do
        result
        expect(File).to have_received(:write).with(output_path, "Just plain subtitle text")
      end
    end
  end
end
