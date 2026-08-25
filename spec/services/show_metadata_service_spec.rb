require "rails_helper"

RSpec.describe ShowMetadataService do
  describe ".call" do
    subject(:call) { described_class.call(show) }

    let(:source_path) { "/path/to/show" }
    let(:cover_art_association) { instance_double(ActiveStorage::Attached::One) }
    let(:show) { instance_double("Show", id: 123, source_path: source_path, cover_art: cover_art_association) }

    before do
      allow(cover_art_association).to receive(:attach)
      allow(Marcel::MimeType).to receive(:for)
      allow(File).to receive(:file?).and_return(false)
    end

    context "when no supported cover file exists" do
      it "does not attach anything" do
        call

        expect(cover_art_association).not_to have_received(:attach)
      end

      it "returns nil" do
        expect(call).to be_nil
      end
    end

    context "when cover.jpg exists" do
      let(:cover_path) { File.join(source_path, "cover.jpg") }
      let(:file) { instance_double(File) }

      before do
        allow(File).to receive(:file?).with(cover_path).and_return(true)
        allow(File).to receive(:open).with(cover_path).and_return(file)
      end

      it "attaches the cover with a filename based on the show id and original extension" do
        call

        expect(cover_art_association)
          .to have_received(:attach)
          .with(hash_including(filename: "123_cover.jpg"))
      end

      it "determines the content type from the cover file" do
        call

        expect(Marcel::MimeType).to have_received(:for).with(cover_path)
      end
    end

    context "when cover.jpeg exists" do
      let(:cover_path) { File.join(source_path, "cover.jpeg") }
      let(:file) { instance_double(File) }

      before do
        allow(File).to receive(:file?).with(cover_path).and_return(true)
        allow(File).to receive(:open).with(cover_path).and_return(file)
      end

      it "attaches the cover using the jpeg extension" do
        call

        expect(cover_art_association)
          .to have_received(:attach)
          .with(hash_including(filename: "123_cover.jpeg"))
      end

      it "determines the content type from the cover file" do
        call

        expect(Marcel::MimeType).to have_received(:for).with(cover_path)
      end
    end

    context "when cover.png exists" do
      let(:cover_path) { File.join(source_path, "cover.png") }
      let(:file) { instance_double(File) }

      before do
        allow(File).to receive(:file?).with(cover_path).and_return(true)
        allow(File).to receive(:open).with(cover_path).and_return(file)
      end

      it "attaches the cover using the png extension" do
        call

        expect(cover_art_association)
          .to have_received(:attach)
          .with(hash_including(filename: "123_cover.png"))
      end

      it "determines the content type from the cover file" do
        call

        expect(Marcel::MimeType).to have_received(:for).with(cover_path)
      end
    end

    context "when the cover filename has uppercase extension" do
      let(:cover_path) { File.join(source_path, "cover.JPG") }
      let(:file) { instance_double(File) }

      it "is not matched, since SUPPORTED_COVER_NAMES is case-sensitive" do
        call

        expect(cover_art_association).not_to have_received(:attach)
      end
    end

    context "when multiple supported cover files exist" do
      let(:jpg_path) { File.join(source_path, "cover.jpg") }
      let(:jpeg_path) { File.join(source_path, "cover.jpeg") }
      let(:file) { instance_double(File) }

      before do
        allow(File).to receive(:file?).with(jpg_path).and_return(true)
        allow(File).to receive(:file?).with(jpeg_path).and_return(true)
        allow(File).to receive(:open).with(jpg_path).and_return(file)
      end

      it "picks the first match according to SUPPORTED_COVER_NAMES order" do
        call

        expect(cover_art_association)
          .to have_received(:attach)
          .with(hash_including(filename: "123_cover.jpg"))
      end

      it "picks the first match according to SUPPORTED_COVER_NAMES order to determine the content type from the cover file" do
        call

        expect(Marcel::MimeType).to have_received(:for).with(jpg_path)
      end
    end
  end
end
