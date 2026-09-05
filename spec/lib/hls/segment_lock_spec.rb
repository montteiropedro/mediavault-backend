require "rails_helper"

RSpec.describe Hls::SegmentLock do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  before { stub_const("Hls::SegmentLock::BASE_DIR", @tmp_dir) }

  describe ".synchronize" do
    it "executes the provided code block" do
      executed = false

      described_class.synchronize(123, "video", 1) do
        executed = true
      end

      expect(executed).to be(true)
    end

    it "creates the lock file in the correct location" do
      lock_file = @tmp_dir.join("123", "video", "1.lock")

      expect { described_class.synchronize(123, "video", 1) {} }
        .to change { File.exist?(lock_file) }
        .from(false)
        .to(true)
    end

    it "ensures concurrent mutual exclusion (serializes execution via an exclusive lock)" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, "video", 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :thread_1
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(123, "video", 1) do
          execution_order << :thread_2
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:thread_1, :thread_2])
    end

    it "allows parallel concurrency across different segment indexes" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, "video", 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :segment_1
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(123, "video", 2) do
          execution_order << :segment_2
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:segment_2, :segment_1])
    end

    it "allows parallel concurrency across different resource types (e.g., video & audio)" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, "video", 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :video
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(123, "audio", 1) do
          execution_order << :audio
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:audio, :video])
    end

    it "allows parallel concurrency across different playables of the same resource type" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, "video", 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :playable_123
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(456, "video", 1) do
          execution_order << :playable_456
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:playable_456, :playable_123])
    end
  end
end
