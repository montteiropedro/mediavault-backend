require "rails_helper"

RSpec.describe MediaMetadataProcessingJob do
  describe "#perform" do
    context "when the media_item exists" do
      let(:media_item) { instance_double(MediaItem) }
      let(:media_item_id) { 1 }

      before { allow(MediaItem).to receive(:find_by).with(id: media_item_id).and_return(media_item) }

      it "calls MediaMetadataService with the found media_item" do
        expect(MediaMetadataService).to receive(:call).with(media_item)
        described_class.perform_now(media_item_id)
      end
    end

    context "when the media_item no longer exists" do
      it "does not call MediaMetadataService" do
        expect(MediaMetadataService).not_to receive(:call)
        described_class.perform_now(999)
      end
    end
  end

  it "is enqueued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
