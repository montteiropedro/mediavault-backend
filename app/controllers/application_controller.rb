class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_user!

  private

  def authenticate_user!
    # Tenta ler do cookie criptografado (Web). Se não achar, tenta ler do Header (Mobile).
    token = cookies.encrypted[:api_token] || request.headers['Authorization']&.split(' ')&.last

    @current_user = User.authenticate_by_token(token)
    render status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
