class CollectionsController < ApplicationController

  def show
    @collection = Collection.find(params[:id])
    authorize @collection
    @community = Community.find(@collection.community_id)
  end

  def new
    @collection = Collection.new_locked_ldp_object(community_id: params[:community_id])
    authorize @collection
    @community = Community.find(params[:community_id])
  end

  def create
    @collection = Collection.new_locked_ldp_object(collection_params)
    authorize @collection
    @community = Community.find(params[:community_id])
    @collection.unlock_and_fetch_ldp_object(&:save!)

    redirect_to community_collection_path(@community, @collection)
  end

  protected

  def collection_params
    params.require(:collection).permit(policy(Collection).permitted_attributes)
  end

end
