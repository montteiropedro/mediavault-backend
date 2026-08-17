require "rails_helper"

RSpec.describe ScanMediaService do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_library_path = tmp_dir
      example.run
    end
  end

  def create_file(relative_path)
    full_path = File.join(@tmp_library_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    FileUtils.touch(full_path)
    full_path
  end

  describe ".call" do
    subject(:call) { described_class.call(@tmp_library_path) }

    context "when the library has new supported files" do
      let!(:video_path) { create_file("path/to/some_movie.mp4") }
      let!(:audio_path) { create_file("path/to/some_song.mp3") }

      it "creates a MediaItem for each supported file" do
        expect { call }.to change(MediaItem, :count).by(2)
      end

      it "sets title, media_type and description correctly" do
        call

        video_item = MediaItem.find_by(file_path: video_path)
        expect(video_item.title).to eq("Some Movie")
        expect(video_item.media_type).to eq("video")
        expect(video_item.description).to eq("Auto-indexed from local storage.")
      end

      it "classifies audio extensions as audio" do
        call

        audio_item = MediaItem.find_by(file_path: audio_path)
        expect(audio_item.media_type).to eq("audio")
      end

      it "enqueues MediaMetadataProcessingJob for each new item" do
        expect { call }.to have_enqueued_job(MediaMetadataProcessingJob).twice
      end
    end

    context "when a file has an unsupported extension" do
      before { create_file("notes.txt") }

      it "does not create a MediaItem for it" do
        expect { call }.not_to change(MediaItem, :count)
      end
    end

    context "when a file is already indexed" do
      let!(:existing_path) { create_file("path/to/already_indexed.mp4") }
      let!(:existing_item) { MediaItem.create!(title: "Already Indexed", file_path: existing_path, media_type: :video) }

      it "does not duplicate the record" do
        expect { call }.not_to change(MediaItem, :count)
      end

      it "does not enqueue a new metadata job" do
        expect { call }.not_to have_enqueued_job(MediaMetadataProcessingJob)
      end
    end

    context "when a database record no longer exists on disk" do
      let!(:orphan_item) do
        MediaItem.create!(
          title: "Deleted File",
          file_path: File.join(@tmp_library_path, "deleted_file.mp4"),
          media_type: :video
        )
      end

      it "removes the record" do
        expect { call }.to change(MediaItem, :count).by(-1)
        expect(MediaItem.exists?(orphan_item.id)).to be(false)
      end
    end
  end
end
