class Digitization::ImagesController < ApplicationController
  before_action :set_digitization_image, only: [:show]

  def show
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_digitization_image
      @digitization_image = Digitization::Image.find(params[:id])
      authorize @digitization_image
    end

    # Only allow a list of trusted parameters through.
    def digitization_image_params
      params.require(:digitization_image).permit(:peel_image_id)
    end
end
