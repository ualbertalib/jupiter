class Digitization::BooksController < ApplicationController

  def show
    @digitization_book = Digitization::Book.find(params[:id])
    authorize @digitization_book
  end

end
