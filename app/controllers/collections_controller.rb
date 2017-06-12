class CollectionsController < ApplicationController

  def show
    @collection = Collection.find(params[:id])
    @community = Community.find(@collection.community_id)
  end

  def new
    @community = Community.find(params[:community_id])
    @collection = Collection.new(community_id: params[:community_id])
  end

  def create
    @community = Community.find(params[:community_id])
    @collection = Collection.create!(collection_params)
    redirect_to community_collection_path(@community, @collection)
  end

  protected

  def collection_params
    params[:collection].permit(Collection.property_names)
  end

end