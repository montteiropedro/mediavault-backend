require "rails_helper"

RSpec.describe Playable::MetadataProcessingJob do
  describe "#perform" do
    before do
      allow(Playable::MetadataService).to receive(:call)
    end

    context "when playable is a Movie" do
      let(:playable) { build(:movie) }

      before { allow(playable).to receive(:is_a?).and_call_original }

      it "calls Playable::MetadataService with the movie" do
        described_class.perform_now(playable)

        expect(Playable::MetadataService).to have_received(:call).with(playable)
      end
    end

    context "when playable is an Episode" do
      let(:playable) { build(:episode) }

      it "calls Playable::MetadataService with the episode" do
        described_class.perform_now(playable)

        expect(Playable::MetadataService).to have_received(:call).with(playable)
      end
    end

    context "when playable is an unsupported type" do
      let(:playable) { build(:season) }

      before { allow(ApplicationLogger).to receive(:warn) }

      it "does not call Playable::MetadataService" do
        described_class.perform_now(playable)

        expect(Playable::MetadataService).not_to have_received(:call)
      end

      it "logs a warning with the unsupported class name" do
        described_class.perform_now(playable)

        expect(ApplicationLogger)
          .to have_received(:warn)
          .with("Unsupported playable type", { location: "Season" })
      end
    end
  end

  it "is enqueued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
