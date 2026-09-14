class JobProgress
  KEY_PREFIX = "job_progress"
  TTL = 1.hour.to_i

  def self.read(job_id)
    raw = Sidekiq.redis { |conn| conn.get(state_key(job_id)) }
    raw ? JSON.parse(raw) : nil
  end

  def self.async_item_completed!(job_id, item_key)
    meta_raw = Sidekiq.redis { |conn| conn.get(async_key(job_id)) }
    return unless meta_raw

    meta = JSON.parse(meta_raw)
    items_completed = Sidekiq.redis do |conn|
      conn.sadd(done_key(job_id), item_key)
      conn.scard(done_key(job_id))
    end

    percent = meta["base_percent"] + ((items_completed.to_f / meta["total"]) * meta["weight"]).round
    status = items_completed >= meta["total"] ? "completed" : "running"

    write_state(job_id, percent: percent, status: status, phase: meta["phase"])
  end

  def initialize(job_id)
    @job_id = job_id
    @completed_weight = 0
  end

  def run(name, weight:)
    @current_phase_weight = weight
    write_state(@job_id, percent: @completed_weight, status: "running", phase: name)

    result = yield self
    @completed_weight += weight
    result
  end

  def step(current, total)
    return if total.zero?

    percent = @completed_weight + ((current.to_f / total) * @current_phase_weight).round
    write_state(@job_id, percent: percent, status: "running")
  end

  def run_async(name, weight:, total:)
    if total.zero?
      @completed_weight += weight
      return write_state(@job_id, percent: @completed_weight, status: "running", phase: name)
    end

    meta = { phase: name, total: total, weight: weight, base_percent: @completed_weight }
    Sidekiq.redis { |conn| conn.set(self.class.async_key(@job_id), meta.to_json, ex: TTL) }
    write_state(@job_id, percent: @completed_weight, status: "running", phase: name)
  end

  def complete!
    write_state(@job_id, percent: 100, status: "completed")
  end

  def fail!(error)
    write_state(@job_id, percent: nil, status: "failed", error: error)
  end

  def self.state_key(job_id) = "#{KEY_PREFIX}:#{job_id}"
  def self.async_key(job_id) = "#{KEY_PREFIX}:#{job_id}:async"
  def self.done_key(job_id) = "#{KEY_PREFIX}:#{job_id}:async_done"

  def self.write_state(job_id, data)
    Sidekiq.redis { |conn| conn.set(state_key(job_id), data.to_json, ex: TTL) }
  end
  private_class_method :write_state

  private

  def write_state(job_id, data)
    self.class.send(:write_state, job_id, data)
  end
end
