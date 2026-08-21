Sidekiq::Cron.configure do |config|
  config.enabled = true
  config.cron_poll_interval = 30
  config.cron_schedule_file = 'config/schedule.yml'
  config.cron_history_size = 10
  config.default_namespace = 'default'
  config.available_namespaces = %w[default]
  config.natural_cron_parsing_mode = :single
  config.reschedule_grace_period = 60
end
