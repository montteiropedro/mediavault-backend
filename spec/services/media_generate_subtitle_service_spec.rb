require "rails_helper"

RSpec.describe MediaGenerateSubtitleService do
  let(:media_item) { instance_double("MediaItem", file_path: "/path/to/movie.mp4") }
  let(:track_index) { 1 }
  let(:output_path) { Pathname.new("/tmp/subtitles/track_1.vtt") }

  describe ".call" do
    it "calls ffmpeg to generate the subtitle track as webvtt" do
      expect(Open3).to receive(:capture3).with(
        "ffmpeg",
        "-y",
        "-v", "error",
        "-i", "/path/to/movie.mp4",
        "-map", "0:s:1",
        "-f", "webvtt",
        "/tmp/subtitles/track_1.vtt"
      ).and_return(["", "", instance_double(Process::Status)])

      described_class.new(media_item, track_index, output_path).call
    end
  end
end
