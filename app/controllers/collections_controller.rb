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
    @collection = Collection.new_locked_ldp_object(permitted_attributes(Collection))
    authorize @collection
    @community = Community.find(params[:community_id])
    @collection.unlock_and_fetch_ldp_object(&:save!)

    redirect_to community_collection_path(@community, @collection)
  end

  def edit
    @community = Community.find(params[:community_id])
    @collection = Collection.find(params[:id])
  end

  def update
    @collection = Collection.find(params[:id])
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      unlocked_collection.update!(collection_params)
    end
    flash[:notice] = 'Collection updated'
    redirect_to admin_communities_and_collections_path
  end

  def destroy
    collection = Collection.find(params[:id])
    collection.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = 'Collection deleted'
      else
        flash[:alert] = 'Cannot delete a non-empty Collection'
      end

      redirect_to admin_communities_and_collections_path
    end
  end

  protected

  def collection_params
    params[:collection].permit(Collection.attribute_names)
  end

end
