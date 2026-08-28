module RequestHelpers
  def login(user)
    post "/api/v1/session", params: { username: user.username, token: user.raw_token }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
