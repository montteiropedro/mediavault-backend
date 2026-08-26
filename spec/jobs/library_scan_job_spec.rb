require "rails_helper"

RSpec.describe LibraryScanJob do
  describe "#perform" do
    before do
      allow(ScanMoviesService).to receive(:call)
      allow(ScanShowsService).to receive(:call)
    end

    it "calls ScanMoviesService" do
      described_class.perform_now

      expect(ScanMoviesService).to have_received(:call)
    end

    it "calls ScanShowsService" do
      described_class.perform_now

      expect(ScanShowsService).to have_received(:call)
    end
  end

  it "is enqueued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
