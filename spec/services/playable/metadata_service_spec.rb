require "rails_helper"

RSpec.describe Playable::MetadataService do
  describe ".call" do
    subject(:call) { described_class.call(playable) }

    let(:file_path) { "/path/to/playable.mkv" }
    let(:image_association) { instance_double(ActiveStorage::Attached::One) }
    let(:playable) { instance_double("Movie", id: 123, file_path: file_path, cover_art: image_association) }

    let(:ffprobe_status) { instance_double(Process::Status, success?: ffprobe_success) }

    let(:ffmpeg_success) { true }
    let(:ffmpeg_stderr) { "" }
    let(:ffmpeg_exitstatus) { 0 }
    let(:ffmpeg_status) { instance_double(Process::Status, success?: ffmpeg_success) }
    let(:ffmpeg_invocations) { [] }

    before do
      allow(playable).to receive(:duration_seconds=)
      allow(playable).to receive(:audio_tracks=)
      allow(playable).to receive(:subtitle_tracks=)
      allow(playable).to receive(:save!).and_return(true)
      allow(image_association).to receive(:attach)
      allow(ApplicationLogger).to receive(:error)
      allow(Marcel::MimeType).to receive(:for).and_return("image/jpeg")

      allow(Open3).to receive(:capture3) do |*args|
        case args.first
        when "ffprobe"
          [ffprobe_stdout, ffprobe_stderr, ffprobe_status]
        when "ffmpeg"
          ffmpeg_invocations << args
          tmp_path = args.last
          File.write(tmp_path, "fake-cover-bytes") if ffmpeg_success
          ["", ffmpeg_stderr, ffmpeg_status]
        end
      end
    end

    context "when ffprobe succeeds" do
      let(:ffprobe_success) { true }
      let(:ffprobe_stderr) { "" }
      let(:ffprobe_stdout) do
        {
          format: { duration: "125.789" },
          streams: [
            { codec_type: "video", index: 0, codec_name: "h264", disposition: { attached_pic: 0 }, tags: {} },
            { codec_type: "audio", tags: { language: "por", title: "Portuguese (Brazil)" } },
            { codec_type: "audio", tags: { language: "eng" } },
            { codec_type: "subtitle", tags: { language: "por", title: "Portuguese (Brazil)" } },
            { codec_type: "subtitle", tags: { language: "eng" } },
            { codec_type: "subtitle", tags: {} }
          ]
        }.to_json
      end

      it "persists the rounded duration" do
        call

        expect(playable).to have_received(:duration_seconds=).with(126)
      end

      it "persists audio tracks formatted as hashes" do
        call

        expect(playable).to have_received(:audio_tracks=).with(
          [
            { id: 0, language: "por", label: "Portuguese (Brazil)" },
            { id: 1, language: "eng", label: "eng" }
          ]
        )
      end

      it "persists subtitle tracks, falling back to 'subtitle N' as label" do
        call

        expect(playable).to have_received(:subtitle_tracks=).with(
          [
            { id: 0, language: "por", label: "Portuguese (Brazil)" },
            { id: 1, language: "eng", label: "eng" },
            { id: 2, language: "und", label: "subtitle 3" }
          ]
        )
      end

      it "saves the playable and returns the result of save!" do
        expect(call).to eq(true)
        expect(playable).to have_received(:save!)
      end

      it "does not call ffmpeg when no video stream is a cover" do
        call

        expect(ffmpeg_invocations).to be_empty
        expect(image_association).not_to have_received(:attach)
      end
    end

    context "when format/duration is missing" do
      let(:ffprobe_success) { true }
      let(:ffprobe_stderr) { "" }
      let(:ffprobe_stdout) { { streams: [] }.to_json }

      it "persists a duration of 0 instead of raising" do
        call

        expect(playable).to have_received(:duration_seconds=).with(0)
      end
    end

    context "when ffprobe fails" do
      let(:ffprobe_success) { false }
      let(:ffprobe_exitstatus) { 1 }
      let(:ffprobe_stderr) { "stderr" }
      let(:ffprobe_stdout) { "{}" }

      it "logs the error and returns false without persisting anything" do
        expect(call).to eq(false)
        expect(ApplicationLogger)
          .to have_received(:error)
          .with(an_instance_of(RuntimeError), location: described_class.to_s)
        expect(playable).not_to have_received(:duration_seconds=)
        expect(playable).not_to have_received(:audio_tracks=)
        expect(playable).not_to have_received(:subtitle_tracks=)
        expect(playable).not_to have_received(:save!)
      end
    end

    context "cover art extraction when playable is a Movie" do
      let(:ffprobe_success) { true }
      let(:ffprobe_stderr) { "" }

      context "when the video stream has the attached_pic disposition" do
        let(:ffprobe_stdout) do
          {
            format: { duration: "10" },
            streams: [
              { codec_type: "video", index: 1, codec_name: "mjpeg", disposition: { attached_pic: 1 }, tags: {} }
            ]
          }.to_json
        end

        it "extracts and attaches the cover with the correct extension for the codec" do
          call

          expect(image_association)
            .to have_received(:attach)
            .with(hash_including(filename: "123_cover.jpg", content_type: "image/jpeg"))
        end

        it "removes the temporary file after attaching" do
          call

          tmp_path = ffmpeg_invocations.last.last
          expect(File.exist?(tmp_path)).to eq(false)
        end
      end

      context "when the stream has a MIMETYPE tag indicating an image" do
        let(:ffprobe_stdout) do
          {
            format: {},
            streams: [
              { codec_type: "video", index: 1, codec_name: "png", disposition: {}, tags: { "MIMETYPE" => "image/png" } }
            ]
          }.to_json
        end

        it "identifies the cover by mimetype and uses the matching extension" do
          call

          expect(image_association)
            .to have_received(:attach)
            .with(hash_including(filename: "123_cover.png"))
        end
      end

      context "when the stream has a FILENAME tag with an image extension" do
        let(:ffprobe_stdout) do
          {
            format: {},
            streams: [
              { codec_type: "video", index: 1, codec_name: "bmp", disposition: {}, tags: { "FILENAME" => "cover.bmp" } }
            ]
          }.to_json
        end

        it "identifies the cover by filename" do
          call

          expect(image_association)
            .to have_received(:attach)
            .with(hash_including(filename: "123_cover.bmp"))
        end
      end

      context "when the cover codec has no explicit mapping" do
        let(:ffprobe_stdout) do
          {
            format: {},
            streams: [
              { codec_type: "video", index: 1, codec_name: "webp", disposition: { attached_pic: 1 }, tags: {} }
            ]
          }.to_json
        end

        it "falls back to jpg as the default extension" do
          call

          expect(image_association)
            .to have_received(:attach)
            .with(hash_including(filename: "123_cover.jpg"))
        end
      end

      context "when ffmpeg fails to extract the cover" do
        let(:ffprobe_stdout) do
          {
            format: {},
            streams: [
              { codec_type: "video", index: 1, codec_name: "mjpeg", disposition: { attached_pic: 1 }, tags: {} }
            ]
          }.to_json
        end
        let(:ffmpeg_success) { false }
        let(:ffmpeg_exitstatus) { 1 }
        let(:ffmpeg_stderr) { "ffmpeg error" }

        it "logs the error, skips attaching the cover, but still saves the other metadata" do
          expect(call).to eq(true)
          expect(ApplicationLogger)
            .to have_received(:error)
            .with(an_instance_of(RuntimeError), location: described_class.to_s)
          expect(image_association).not_to have_received(:attach)
          expect(playable).to have_received(:save!)
        end
      end
    end

    context "thumbnail extraction when playable is a Episode" do
      let(:playable) { instance_double("Episode", id: 456, duration_seconds: 1000, file_path: file_path, thumbnail: image_association) }
      let(:ffprobe_stderr) { "" }
      let(:ffprobe_stdout) { "_stdout".to_json }
      let(:ffprobe_success) { true }

      it "extracts and attaches a thumbnail from the episode video" do
        call

        expect(image_association)
          .to have_received(:attach)
          .with(hash_including(filename: "456_thumbnail.jpg", content_type: "image/jpeg"))
      end

      it "removes the temporary file after attaching" do
        call

        tmp_path = ffmpeg_invocations.last.last
        expect(File.exist?(tmp_path)).to eq(false)
      end

      context "when ffmpeg fails to extract the thumbnail" do
        let(:ffprobe_stdout) { "_stdout".to_json }
        let(:ffmpeg_success) { false }

        it "logs the error, skips attaching the thumbnail, but still saves the other metadata" do
          expect(call).to eq(true)
          expect(ApplicationLogger)
            .to have_received(:error)
            .with(
              an_object_having_attributes(message: "Failed to extract thumbnail"),
              location: described_class.to_s
            )
          expect(image_association).not_to have_received(:attach)
          expect(playable).to have_received(:save!)
        end
      end
    end
  end
end
