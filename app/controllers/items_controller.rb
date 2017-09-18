class ItemsController < ApplicationController

  before_action :load_item, only: [:show, :edit, :update]

  def new
    @item = Item.new_locked_ldp_object
    authorize @item
  end

  def create
    communities = params[:item].delete :community
    collections = params[:item].delete :collection

    @item = Item.new_locked_ldp_object(permitted_attributes(Item))
    authorize @item

    # TODO: add validations?
    @item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.owner = current_user.id
      unlocked_item.add_communities_and_collections(communities, collections)
      unlocked_item.add_files(params)
      unlocked_item.save!
    end
    redirect_to @item
  end

  def update
    communities = params[:item].delete :community
    collections = params[:item].delete :collection

    authorize @item
    @item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.update_attributes(permitted_attributes(@item))
      unlocked_item.add_communities_and_collections(communities, collections)
      unlocked_item.add_files(params)
      unlocked_item.save!
    end
    redirect_to @item
  end

  def search
    @results = Item.search(q: params[:q])
    authorize @results, :index?
  end

  private

  def load_item
    @item = Item.find(params[:id])
    authorize @item
  end

end
