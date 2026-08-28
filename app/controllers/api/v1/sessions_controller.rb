class Api::V1::SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  def create
    user = User.authenticate(username: params[:username], raw_token: params[:token])

    if user
      cookies.encrypted[:api_token] = {
        value: params[:token],
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 30.days.from_now
      }

      render json: UserSerializer.new(user).serialize, status: :ok
    else
      render status: :unauthorized
    end
  end

  def destroy
    cookies.delete(:api_token)
    head :no_content
  end
end
