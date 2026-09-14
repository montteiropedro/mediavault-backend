class Api::V1::Jobs::ProgressController < ApplicationController
  def show
    data = JobProgress.read(params[:job_id])
    return render status: :not_found unless data

    render json: data
  end
end
