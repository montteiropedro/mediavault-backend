require "sidekiq/web"

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  expected_username = ENV.fetch("SIDEKIQ_USERNAME")
  expected_password = ENV.fetch("SIDEKIQ_PASSWORD")

  ActiveSupport::SecurityUtils.secure_compare(
    username,
    expected_username
  ) &&
    ActiveSupport::SecurityUtils.secure_compare(
      password,
      expected_password
    )
end
