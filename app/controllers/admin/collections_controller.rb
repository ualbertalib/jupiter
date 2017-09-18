class Admin::CollectionsController < Admin::AdminController

  def show
    @community = Community.find(params[:community_id])
    @collection = Collection.find(params[:id])

    respond_to do |format|
      format.js
      format.html { render template: 'collections/show' }
    end
  end

  def new
    @community = Community.find(params[:community_id])
    @collection = Collection.new_locked_ldp_object(community_id: params[:community_id])
  end

  def create
    @community = Community.find(params[:community_id])
    @collection =
      Collection.new_locked_ldp_object(permitted_attributes(Collection).merge(owner: current_user&.id))

    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.save
        redirect_to admin_community_collection_path(@community, @collection), notice: t('.created')
      else
        render :new, status: :bad_request
      end
    end
  end

  def edit
    @community = Community.find(params[:community_id])
    @collection = Collection.find(params[:id])
  end

  def update
    @community = Community.find(params[:community_id])
    @collection = Collection.find(params[:id])

    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.update(permitted_attributes(Collection))
        redirect_to admin_community_collection_path(@community, @collection), notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    collection = Collection.find(params[:id])
    community = Community.find(params[:community_id])
    collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
      end

      redirect_to admin_community_path(community)
    end
  end

end
