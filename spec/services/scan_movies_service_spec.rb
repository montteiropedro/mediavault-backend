require "rails_helper"

RSpec.describe ScanMoviesService do
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
      let!(:mp4_video_path) { create_file("path/to/test_movie.mp4") }
      let!(:mkv_video_path) { create_file("path/to/test_movie_2.mkv") }

      it "creates a Movie for each supported file" do
        expect { call }.to change(Movie, :count).by(2)
      end

      it "sets title correctly" do
        call

        video_item = Movie.find_by(file_path: mp4_video_path)
        expect(video_item.title).to eq("Test Movie")
      end

      it "classifies audio extensions as audio" do
        call

        audio_item = Movie.find_by(file_path: mkv_video_path)
      end

      it "enqueues MediaMetadataProcessingJob for each new item" do
        expect { call }.to have_enqueued_job(Playable::MetadataProcessingJob).twice
      end
    end

    context "when a file has an unsupported extension" do
      before { create_file("notes.txt") }

      it "does not create a Movie for it" do
        expect { call }.not_to change(Movie, :count)
      end
    end

    context "when a file is already indexed" do
      let!(:existing_path) { create_file("path/to/already_indexed.mp4") }
      let!(:existing_item) { create(:movie, title: "Already Indexed", file_path: existing_path) }

      it "does not duplicate the record" do
        expect { call }.not_to change(Movie, :count)
      end

      it "does not enqueue a new metadata job" do
        expect { call }.not_to have_enqueued_job(Playable::MetadataProcessingJob)
      end
    end

    context "when a database record no longer exists on disk" do
      let!(:orphan_item) do
        create(:movie, title: "Deleted File", file_path: File.join(@tmp_library_path, "deleted_file.mp4"))
      end

      it "removes the record" do
        expect { call }.to change(Movie, :count).by(-1)
        expect(Movie.exists?(orphan_item.id)).to be(false)
      end
    end
  end
end
