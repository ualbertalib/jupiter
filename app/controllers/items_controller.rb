class ItemsController < ApplicationController

  after_action :update_item_statistics, only: :show, unless: -> { request.bot? }

  def show
    @item = JupiterCore::LockedLdpObject.find(params[:id], types: [Item, Thesis])
    authorize @item
    @views_count, @downloads_count = fetch_item_statistics
  end

  def edit
    # Note that only Items can be edited -- there is no deposit or edit interface for Theses:
    item = Item.find(params[:id])
    authorize item

    draft_item = DraftItem.from_item(item, for_user: current_user)

    redirect_to item_draft_path(id: Wicked::FIRST_STEP, item_id: draft_item.id)
  end

  private

  def update_item_statistics
    Statistics.increment_view_count_for(item_id: params[:id], ip: request.ip)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, show pages don't start crashing
    Rollbar.error("Error incrementing view count for #{params[:id]}", e)
  end

  def fetch_item_statistics
    return Statistics.for(item_id: @item.id)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, show pages don't start crashing
    Rollbar.error("Error retriving statistics for #{@item.id}", e)

    # we'll display unavailable counts
    return [0, 0]
  end

end
