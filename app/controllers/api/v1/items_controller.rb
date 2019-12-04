class Api::V1::ItemsController < ApplicationController
  include ItemLoad

  before_action :load_item, only: [:show]

  def show
    authorize @item    
    render json: {status: 'SUCCESS', data: @item}, status: :ok
  end

end