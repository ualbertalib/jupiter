class Digitization::ImagesController < ApplicationController

  def show
    @digitization_image = Digitization::Image.find(params[:id])
    authorize @digitization_image
  end

end
