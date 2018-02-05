class ItemsController < ApplicationController

  def show
    @item = JupiterCore::LockedLdpObject.find(params[:id], types: [Item, Thesis])
    authorize @item
  end

  def edit
    # Note that only Items can be editted -- there is no deposit or edit interface for Theses:
    item = Item.find(params[:id])
    authorize item

    draft_item = DraftItem.from_item(item)

    redirect_to item_draft_path(id: Items::DraftController::FIRST_STEP, item_id: draft_item.id)
  end

end
