class Api::V1::MediaProgressesController < ApplicationController
  before_action :set_media_item, only: [:create]

  def create
    user = User.first
    progress = MediaProgress.find_or_initialize_by(
      user: user,
      media_item: @media_item
    )

    progress.assign_attributes(
      progress_seconds: progress_params[:progress_seconds].floor,
      last_watched_at: Time.current
    )

    if progress.save
      render json: progress, status: :ok
    else
      render json: { errors: progress.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def progress_params
    params.require(:media_progress).permit(:user_id, :progress_seconds)
  end

  def set_media_item
    @media_item = MediaItem.find(params[:media_item_id])
  end
end
