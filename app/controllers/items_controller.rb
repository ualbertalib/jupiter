class ItemsController < ApplicationController

  after_action :update_item_statistics, only: :show, unless: -> { request.bot? }
  before_action :load_item, only: [:show, :edit]

  def show
    authorize @item
    @views_count, @downloads_count = fetch_item_statistics
  end

  def edit
    authorize @item

    if @item.is_a? Thesis
      draft_thesis = DraftThesis.from_thesis(@item, for_user: current_user)

      redirect_to admin_thesis_draft_path(id: Wicked::FIRST_STEP, thesis_id: draft_thesis.id)
    else
      draft_item = DraftItem.from_item(@item, for_user: current_user)

      redirect_to item_draft_path(id: Wicked::FIRST_STEP, item_id: draft_item.id)
    end
  end

  private

  def load_item
    @item = begin
      Item.find(params[:id]).decorate
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id]).decorate
    end
  end

  def update_item_statistics
    Statistics.increment_view_count_for(item_id: params[:id], ip: request.ip)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, show pages don't start crashing
    Rollbar.error("Error incrementing view count for #{params[:id]}", e)
  end

  def fetch_item_statistics
    Statistics.for(item_id: @item.id)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, show pages don't start crashing
    Rollbar.error("Error retriving statistics for #{@item.id}", e)

    # we'll display unavailable counts
    [0, 0]
  end

end
