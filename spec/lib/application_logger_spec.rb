require "rails_helper"

RSpec.describe ApplicationLogger do
  describe ".info" do
    let(:message) { "Test Message" }
    let(:location) { "TestController" }
    let(:context) { { test_id: 50, foo: "bar" } }

    it "sends the string in the expected format to Rails.logger.info" do
      freeze_time do
        expect(Rails.logger).to receive(:info) do |log_message|
          expect(log_message).to include("[INFO]")
          expect(log_message).to include("#{Time.current}")
          expect(log_message).to include("location=TestController")
          expect(log_message).to include("test_id=50 foo=bar")
          expect(log_message).to include(": Test Message")
        end

        ApplicationLogger.info(message, location: location, context: context)
      end
    end
  end

  describe ".warn" do
    let(:message) { "Test Message" }
    let(:location) { "TestController" }
    let(:context) { { test_id: 50, foo: "bar" } }

    it "sends the string in the expected format to Rails.logger.warn" do
      freeze_time do
        expect(Rails.logger).to receive(:warn) do |log_message|
          expect(log_message).to include("[WARN]")
          expect(log_message).to include("#{Time.current}")
          expect(log_message).to include("location=TestController")
          expect(log_message).to include("test_id=50 foo=bar")
          expect(log_message).to include(": Test Message")
        end

        ApplicationLogger.warn(message, location: location, context: context)
      end
    end
  end

  describe ".error" do
    let(:exception) do
      StandardError.new("Something went wrong").tap do |e|
        e.set_backtrace([
          "app/models/test.rb:10",
          "app/controllers/test_controller.rb:5"
        ])
      end
    end
    let(:location) { "TestController" }
    let(:context) { { test_id: 50, foo: "bar" } }

    it "sends the string in the expected format to Rails.logger.error" do
      freeze_time do
        expect(Rails.logger).to receive(:error) do |log_message|
          expect(log_message).to include("[ERROR]")
          expect(log_message).to include("#{Time.current}")
          expect(log_message).to include("location=TestController")
          expect(log_message).to include("error=StandardError")
          expect(log_message).to include("test_id=50 foo=bar")
          expect(log_message).to include(": Something went wrong")
          expect(log_message).to include("[BACKTRACE]")
          expect(log_message).to include("app/models/test.rb:10")
          expect(log_message).to include("app/controllers/test_controller.rb:5")
        end

        ApplicationLogger.error(exception, location: location, context: context)
      end
    end
  end
end
