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
      described_class.synchronize(123, 1) do
        executed = true
      end

      expect(executed).to be(true)
    end

    it "creates the lock file in the correct location" do
      lock_file = @tmp_dir.join("123", "1.lock")

      expect { described_class.synchronize(123, 1) {} }
        .to change { File.exist?(lock_file) }
        .from(false)
        .to(true)
    end

    it "ensures concurrent mutual exclusion (serializes execution via an exclusive lock)" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :thread_1
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(123, 1) do
          execution_order << :thread_2
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:thread_1, :thread_2])
    end

    it "allows parallel concurrency across different segments or media" do
      execution_order = []
      thread_1_holding_lock = false

      t1 = Thread.new do
        described_class.synchronize(123, 1) do
          thread_1_holding_lock = true
          sleep(0.1)
          execution_order << :midia_123_seg_1
        end
      end

      sleep(0.01) until thread_1_holding_lock

      t2 = Thread.new do
        described_class.synchronize(123, 2) do
          execution_order << :midia_123_seg_2
        end
      end

      t1.join
      t2.join

      expect(execution_order).to eq([:midia_123_seg_2, :midia_123_seg_1])
    end
  end
end
