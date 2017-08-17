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
    authorize @community
    @collection = Collection.find(params[:id])
    authorize @collection
  end

  def update
    @collection = Collection.find(params[:id])
    authorize @collection
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      unlocked_collection.update!(permitted_attributes(Collection))
    end
    flash[:notice] = I18n.t('application.collections.updated')
    redirect_to admin_communities_and_collections_path
  end

  def destroy
    collection = Collection.find(params[:id])
    authorize collection
    collection.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = I18n.t('application.collections.deleted')
      else
        flash[:alert] = I18n.t('application.collections.not_empty_error')
      end

      redirect_to admin_communities_and_collections_path
    end
  end

end
