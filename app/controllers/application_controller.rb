class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_user!

  private

  def authenticate_user!
    token = cookies.encrypted[:api_token]
    @current_user = User.authenticate_by_token(token)
    render status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
