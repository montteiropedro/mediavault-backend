require "rails_helper"

RSpec.describe LibraryScanJob do
  describe "#perform" do
    before do
      allow(ScanMoviesService).to receive(:call).and_return([])
      allow(ScanShowsService).to receive(:call).and_return([])
    end

    it "calls ScanMoviesService" do
      described_class.perform_now

      expect(ScanMoviesService).to have_received(:call)
    end

    it "calls ScanShowsService" do
      described_class.perform_now

      expect(ScanShowsService).to have_received(:call)
    end

    it "enqueues metadata processing for new playable records" do
      movie = build(:movie)
      episode = build(:episode)
      allow(ScanMoviesService).to receive(:call).and_return([movie])
      allow(ScanShowsService).to receive(:call).and_return([episode])

      expect(Playable::MetadataProcessingJob).to receive(:perform_later)
        .with(movie, parent_job_id: anything)
      expect(Playable::MetadataProcessingJob).to receive(:perform_later)
        .with(episode, parent_job_id: anything)

      described_class.perform_now
    end
  end

  it "is enqueued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
