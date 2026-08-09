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
            { index: 2, tags: { language: "por", title: "Portuguese (Brazil)" } },
            { index: 3, tags: { language: "eng" } },
            { index: 4, tags: {} }
          ]
        }.to_json
      end

      it "correctly maps and formats the subtitles tracks found" do
        result = described_class.call(file_path)

        expect(result).to eq([
          { id: 0, stream_index: 2, language: "por", label: "Portuguese (Brazil)" },
          { id: 1, stream_index: 3, language: "eng", label: "eng" },
          { id: 2, stream_index: 4, language: "und", label: "Subtitle 3" }
        ])
      end
    end

    context "when the metadata fails" do
      let(:success) { false }
      let(:exitstatus) { 1 }
      let(:stdout) { "{}" }
      let(:stderr) { "error opening file" }

      it "logs the error in ApplicationLogger and returns an empty array" do
        expect(ApplicationLogger).to receive(:error)

        result = described_class.call(file_path)
        expect(result).to eq([])
      end
    end
  end
end
