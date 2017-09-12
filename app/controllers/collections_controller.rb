class CollectionsController < ApplicationController

  before_action -> { authorize :application, :admin? }, except: [:index, :show]

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
    @collection =
      Collection.new_locked_ldp_object(permitted_attributes(Collection)
                                        .merge(owner: current_user&.id))
    authorize @collection
    @collection.unlock_and_fetch_ldp_object(&:save!)

    @community = Community.find(params[:community_id])

    # TODO: success flash message?
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
    flash[:notice] = t('.updated')

    # TODO: Needs to be rethinked (and destroy action for both communties and collections)
    # You can access this from both admin communties and collections index as well as communities show page
    # When your in communities show page and go to edit the collection this shouldn't be redirecting to
    # the admin communities and collections index page, it should go back to the communities show page...no?
    # Perhaps better to only allow this behaviour from admin communities and collections?
    redirect_to admin_communities_and_collections_path
  end

  def destroy
    collection = Collection.find(params[:id])
    authorize collection
    collection.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
      end

      redirect_to admin_communities_and_collections_path
    end
  end

end
