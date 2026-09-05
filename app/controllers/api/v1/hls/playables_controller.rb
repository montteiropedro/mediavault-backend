class Api::V1::Hls::PlayablesController < Api::V1::Hls::BaseController
  private

  def set_playable
    @playable = Library.find_playable(params[:id], type: params[:type])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Playable of type #{params[:type]} not found" }, status: :not_found
  end
end
