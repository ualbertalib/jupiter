class Admin::CollectionsController < Admin::AdminController

  # TODO: shouldn;t need to fetch community on every action?
  # Should be able to retrieve this via `Collection.community` in most places
  before_action :fetch_community

  before_action :fetch_collection, only: [:show, :edit, :update, :destroy]

  def show
    respond_to do |format|
      format.html { render template: 'collections/show' }
    end
  end

  def new
    @communities = Community.all
    @collection = Collection.new_locked_ldp_object(community_id: @community.id)
  end

  def create
    @collection =
      Collection.new_locked_ldp_object(permitted_attributes(Collection)
                .merge(owner: current_user.id))

    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.save
        redirect_to admin_community_collection_path(@collection.community, @collection), notice: t('.created')
      else
        @communities = Community.all # need to repopulate select box on error page
        render :new, status: :bad_request
      end
    end
  end

  def edit
    @communities = Community.all
  end

  def update
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.update(permitted_attributes(Collection))
        # TODO: Need to update every item in the collection to the new community and collection pair
        # How to do this? Remember items can belong to multiple collections.
        # if @collection.community.id != @community.id
        #   @collection.member_items.each do |item|
        #     item.unlock_and_fetch_ldp_object do |unlocked_item|
        #       # Not the right call. Need to figure this out
        #       # unlocked_item.update_communities_and_collections(@collection.community.id, @collection.id)
        #       # unlocked_item.save
        #     end
        #   end
        # end
        redirect_to admin_community_collection_path(@collection.community, @collection), notice: t('.updated')
      else
        @communities = Community.all # need to repopulate select box on error page
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = unlocked_collection.errors.full_messages.first
      end

      redirect_to admin_community_path(@community)
    end
  end

  private

  def fetch_community
    @community = Community.find(params[:community_id])
  end

  def fetch_collection
    @collection = Collection.find(params[:id])
  end

end
