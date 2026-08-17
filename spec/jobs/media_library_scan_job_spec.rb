require "rails_helper"

RSpec.describe MediaLibraryScanJob do
  describe "#perform" do
    it "calls ScanMediaService with the given library_path" do
      expect(ScanMediaService).to receive(:call).with("/custom/path")
      described_class.perform_now("/custom/path")
    end

    it "defaults to /media/library when no path is given" do
      expect(ScanMediaService).to receive(:call).with("/media/library")
      described_class.perform_now
    end
  end

  it "is enqueued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
