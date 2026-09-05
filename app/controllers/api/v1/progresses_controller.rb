class Api::V1::ProgressesController < ApplicationController
  before_action :set_playable

  def create
    progress = Progress.find_or_initialize_by(user: current_user, playable: @playable)
    progress.assign_attributes(
      seconds: progress_params[:seconds].to_f.floor,
      last_watched_at: Time.current
    )

    if progress.save
      render status: :ok
    else
      render json: { errors: progress.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def progress_params
    params.require(:progress).permit(:seconds)
  end

  def set_playable
    @playable = Library.find_playable(params[:id], type: params[:type])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "playable not found" }, status: :not_found
  end
end
