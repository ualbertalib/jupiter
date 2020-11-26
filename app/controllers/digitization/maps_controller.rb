class Digitization::MapsController < ApplicationController

  def show
    @digitization_map = Digitization::Map.find(params[:id])
    authorize @digitization_map
  end

end
