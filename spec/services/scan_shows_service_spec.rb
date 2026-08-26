require "rails_helper"

RSpec.describe ScanShowsService do
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

    context "when the library has a new show with seasons and episodes" do
      let!(:episode_1_path) { create_file("Test Show/Season 1/e01_pilot.mp4") }
      let!(:episode_2_path) { create_file("Test Show/Season 1/e02_continuation.mkv") }

      it "creates a Show" do
        expect { call }.to change(Show, :count).by(1)
      end

      it "creates a Season under the show" do
        call

        show = Show.find_by(source_path: File.join(@tmp_library_path, "Test Show"))
        expect(show.seasons.pluck(:number)).to contain_exactly(1)
      end

      it "creates an Episode for each supported file" do
        expect { call }.to change(Episode, :count).by(2)
      end

      it "sets the show title from the directory name" do
        call

        show = Show.find_by(source_path: File.join(@tmp_library_path, "Test Show"))
        expect(show.title).to eq("Test Show")
      end

      it "sets episode titles from the filename" do
        call

        episode = Episode.find_by(file_path: episode_1_path)
        expect(episode.title).to eq("E01 Pilot")
      end

      it "extracts episode numbers from the filename" do
        call

        episode = Episode.find_by(file_path: episode_2_path)
        expect(episode.number).to eq(2)
      end

      it "enqueues Playable::MetadataProcessingJob for each new episode" do
        expect { call }.to have_enqueued_job(Playable::MetadataProcessingJob).twice
      end
    end

    context "when shows are nested under a category folder" do
      let!(:episode_path) { create_file("animes/Test Anime/Season 1/e01.mp4") }

      it "still creates the Show, treating the category as a grouping folder" do
        expect { call }.to change(Show, :count).by(1)

        show = Show.find_by(source_path: File.join(@tmp_library_path, "animes/Test Anime"))
        expect(show).to be_present
      end

      it "creates the episode under the nested show" do
        expect { call }.to change(Episode, :count).by(1)

        episode = Episode.find_by(file_path: episode_path)
        expect(episode.season.show.title).to eq("Test Anime")
      end
    end

    context "when a folder has no season-like subdirectories" do
      before { create_file("random_docs/readme.txt") }

      it "does not create a Show for it" do
        expect { call }.not_to change(Show, :count)
      end
    end

    context "when a file inside a season has an unsupported extension" do
      before { create_file("Test Show/Season 1/notes.txt") }
      let!(:episode_path) { create_file("Test Show/Season 1/e01.mp4") }

      it "does not create an Episode for the unsupported file" do
        expect { call }.to change(Episode, :count).by(1)
      end
    end

    context "when an episode is already indexed" do
      let!(:show) { create(:show, source_path: File.join(@tmp_library_path, "Test Show")) }
      let!(:season) { create(:season, show: show, number: 1, source_path: File.join(@tmp_library_path, "Test Show/Season 1")) }
      let!(:existing_path) { create_file("Test Show/Season 1/e01.mp4") }
      let!(:existing_episode) { create(:episode, season: season, number: 1, file_path: existing_path) }

      it "does not duplicate the record" do
        expect { call }.not_to change(Episode, :count)
      end

      it "does not enqueue a new metadata job" do
        expect { call }.not_to have_enqueued_job(Playable::MetadataProcessingJob)
      end
    end

    context "when an episode no longer exists on disk" do
      let!(:show) { create(:show, source_path: File.join(@tmp_library_path, "Test Show")) }
      let!(:season) { create(:season, show: show, number: 1, source_path: File.join(@tmp_library_path, "Test Show/Season 1")) }
      let!(:orphan_episode) do
        create(:episode, season: season, number: 1, file_path: File.join(@tmp_library_path, "Test Show/Season 1/deleted.mp4"))
      end

      it "removes the episode" do
        expect { call }.to change(Episode, :count).by(-1)
        expect(Episode.exists?(orphan_episode.id)).to be(false)
      end

      it "removes the season if it has no episodes left" do
        call

        expect(Season.exists?(season.id)).to be(false)
      end

      it "removes the show if it has no seasons left" do
        call

        expect(Show.exists?(show.id)).to be(false)
      end
    end

    context "when an episode is removed but the season still has other episodes" do
      let!(:show) { create(:show, source_path: File.join(@tmp_library_path, "Test Show")) }
      let!(:season) { create(:season, show: show, number: 1, source_path: File.join(@tmp_library_path, "Test Show/Season 1")) }
      let!(:remaining_path) { create_file("Test Show/Season 1/e01.mp4") }
      let!(:remaining_episode) { create(:episode, season: season, number: 1, file_path: remaining_path) }
      let!(:orphan_episode) do
        create(:episode, season: season, number: 2, file_path: File.join(@tmp_library_path, "Test Show/Season 1/deleted.mp4"))
      end

      it "keeps the season and show" do
        call

        expect(Season.exists?(season.id)).to be(true)
        expect(Show.exists?(show.id)).to be(true)
      end
    end
  end
end
