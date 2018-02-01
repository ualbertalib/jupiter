class ItemsController < ApplicationController

  def show
    @item = JupiterCore::LockedLdpObject.find(params[:id], types: [Item, Thesis])
    authorize @item
  end

  # TODO: this is just a temp hack to give edit_item_path calls in templates somewhere to point until draft editing lands
  def edit; end

end
