class ItemsController < ApplicationController

  def show
    @item = JupiterCore::LockedLdpObject.find(params[:id], types: [Item, Thesis])
    authorize @item
  end


  def edit
    item = Item.find(params[:id])
    authorize item

    draft_item = DraftItem.from_item(item)

    redirect_to item_draft_path(id: Items::DraftController::FIRST_STEP, item_id: draft_item.id)
  end

end
