class Digitization::NewspapersController < ApplicationController

  before_action :set_digitization_newspaper, only: [:show]

  def show; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_digitization_newspaper
    @digitization_newspaper = Digitization::Newspaper.find(params[:id])
    authorize @digitization_newspaper
  end

  # Only allow a list of trusted parameters through.
  def digitization_newspaper_params
    params.require(:digitization_newspaper).permit(:publication_code, :year, :month, :day)
  end

end
