class Digitization::MapsController < ApplicationController

  before_action :set_digitization_map, only: [:show]

  def show; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_digitization_map
    @digitization_map = Digitization::Map.find(params[:id])
    authorize @digitization_map
  end

  # Only allow a list of trusted parameters through.
  def digitization_map_params
    params.require(:digitization_map).permit(:peel_map_id)
  end

end
