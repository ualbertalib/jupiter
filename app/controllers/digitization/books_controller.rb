class Digitization::BooksController < ApplicationController
  before_action :set_digitization_book, only: [:show]

  def show
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_digitization_book
      @digitization_book = Digitization::Book.find(params[:id])
      authorize @digitization_book
    end

    # Only allow a list of trusted parameters through.
    def digitization_book_params
      params.require(:digitization_book).permit(:peel_id, :run, :part_number)
    end
end
