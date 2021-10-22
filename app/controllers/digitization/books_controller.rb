class Digitization::BooksController < ApplicationController

  def show
    digitization_book = Digitization::Book.find(params[:id])
    authorize digitization_book
    @digitization_book = digitization_book.decorate
  end

end
