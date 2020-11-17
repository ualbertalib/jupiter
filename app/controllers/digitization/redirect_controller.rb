class Digitization::RedirectController < ApplicationController

  skip_after_action :verify_authorized

  def peel_book
    @book = if Digitization::Book.find_by(
      peel_id: params[:peel_id],
      run: params[:run],
      part_number:
      params[:part_number]
    ).present?
              Digitization::Book.find_by(
                peel_id: params[:peel_id],
                run: params[:run],
                part_number: params[:part_number]
              )
            elsif Digitization::Book.find_by(peel_id: params[:peel_id], part_number: params[:part_number]).present?
              Digitization::Book.find_by(peel_id: params[:peel_id], part_number: params[:part_number])
            else
              Digitization::Book.find_by(peel_id: params[:peel_id])
            end
    redirect_to digitization_book_url(@book), status: :moved_permanently
  end

  def peel_newspaper
    @newspaper = Digitization::Newspaper.find_by(
      publication_code: params[:publication_code],
      year: params[:year],
      month: params[:month],
      day: params[:day]
    )
    redirect_to digitization_newspaper_url(@newspaper), status: :moved_permanently
  end

  def peel_image
    @image = Digitization::Image.find_by(peel_image_id: params[:peel_image_id])
    redirect_to digitization_image_url(@image), status: :moved_permanently
  end

  def peel_map
    @map = Digitization::Map.find_by(peel_map_id: params[:peel_map_id])
    redirect_to digitization_map_url(@map), status: :moved_permanently
  end

end
