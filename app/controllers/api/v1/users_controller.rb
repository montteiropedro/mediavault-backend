class Api::V1::UsersController < ApplicationController
  def me
    render json: UserSerializer.new(current_user).serialize, status: :ok
  end
end
