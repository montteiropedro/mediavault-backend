require "rails_helper"

RSpec.describe MediaMetadataService do
  describe ".call" do
    let(:file_path) { "/path/to/movie.mkv" }
    let(:success) { true }
    let(:exitstatus) { 0 }
    let(:stderr) { "" }
    let(:mock_status) { instance_double(Process::Status, success?: success, exitstatus: exitstatus) }

    before do
      allow(Open3).to receive(:capture3).and_return([stdout, stderr, mock_status])
    end

    context "when the metadata fetch succeeds" do
      let(:stdout) do
        {
          streams: [
            { codec_type: "audio", tags: { language: "por", title: "Portuguese (Brazil)" } },
            { codec_type: "audio", tags: { language: "eng" } },
            { codec_type: "subtitle", tags: { language: "por", title: "Portuguese (Brazil)" } },
            { codec_type: "subtitle", tags: { language: "eng" } },
            { codec_type: "subtitle", tags: {} }
          ]
        }.to_json
      end

      it "correctly filters, maps and formats audio and subtitle streams" do
        result = described_class.call(file_path)

        expect(result).to eq(
          described_class::Result.new(
            audios: [
              described_class::Stream.new(id: 0, language: "por", label: "Portuguese (Brazil)"),
              described_class::Stream.new(id: 1, language: "eng", label: "eng")
            ],
            subtitles: [
              described_class::Stream.new(id: 0, language: "por", label: "Portuguese (Brazil)"),
              described_class::Stream.new(id: 1, language: "eng", label: "eng"),
              described_class::Stream.new(id: 2, language: "und", label: "subtitle 3")
            ]
          )
        )
      end
    end

    context "when the metadata fetch fails" do
      let(:success) { false }
      let(:exitstatus) { 1 }
      let(:stdout) { "{}" }
      let(:stderr) { "stderr" }

      it "logs the error in ApplicationLogger and returns an empty array" do
        expect(ApplicationLogger)
          .to receive(:error)
          .with(an_instance_of(RuntimeError), location: described_class.to_s)

        result = described_class.call(file_path)

        expect(result).to eq(described_class::Result.new(audios: [], subtitles: []))
      end
    end
  end
end
