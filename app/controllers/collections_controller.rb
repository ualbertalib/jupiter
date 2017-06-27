class CollectionsController < ApplicationController

  def show
    @collection = Collection.find(params[:id])
    @community = Community.find(@collection.community_id)
  end

  def new
    @community = Community.find(params[:community_id])
    @collection = Collection.new_locked_ldp_object(community_id: params[:community_id])
  end

  def create
    @community = Community.find(params[:community_id])
    @collection = Collection.new_locked_ldp_object(collection_params)
    @collection.unlock_and_fetch_ldp_object {|c| c.save!}
    
    redirect_to community_collection_path(@community, @collection)
  end

  protected

  def collection_params
    params[:collection].permit(Collection.attribute_names)
  end

end