class Digitization::NewspapersController < ApplicationController

  def show
    @digitization_newspaper = Digitization::Newspaper.find(params[:id])
    authorize @digitization_newspaper
  end

end
