class Aip::V1::ItemsController < ApplicationController

  before_action :load_item, only: [:show]

  def show
    authorize @item
    render json: { item: @item }, status: :ok
  end

  private

  def load_item
    @item = Item.find(params[:id])
  end

end
