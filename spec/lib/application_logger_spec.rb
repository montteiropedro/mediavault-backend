require "rails_helper"

RSpec.describe ApplicationLogger do
  describe ".error" do
    let(:exception) do
      StandardError.new("Something went wrong").tap do |e|
        e.set_backtrace([
          "app/models/test.rb:10",
          "app/controllers/test_controller.rb:5"
        ])
      end
    end
    let(:location) { "TestController#create" }
    let(:context) { { test_id: 50, foo: "bar" } }

    it "sends the string in the expected format to Rails.logger" do
      expect(Rails.logger).to receive(:error) do |log_message|
        expect(log_message).to include("[ERROR]")
        expect(log_message).to include("| Location: TestController#create")
        expect(log_message).to include("| Error: StandardError")
        expect(log_message).to include("| Message: Something went wrong")
        expect(log_message).to include("| Context: test_id=50, foo=bar")
        expect(log_message).to include("| Backtrace:")
        expect(log_message).to include("app/models/test.rb:10")
        expect(log_message).to include("app/controllers/test_controller.rb:5")
      end

      ApplicationLogger.error(exception, location: location, context: context)
    end

    context "when the context and backtrace are empty" do
      let(:clean_exception) { StandardError.new("Simple error") }

      it "formats optional fields with hyphens (-)" do
        expect(Rails.logger).to receive(:error) do |log_message|
          expect(log_message).to include("| Context: -")
          expect(log_message).to include("| Backtrace: -")
        end

        ApplicationLogger.error(clean_exception, location: location)
      end
    end
  end
end
