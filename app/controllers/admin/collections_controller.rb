class Admin::CollectionsController < Admin::AdminController

  before_action :fetch_community
  before_action :fetch_collection, only: [:show, :edit, :update, :destroy]

  def show
    respond_to do |format|
      format.html { render template: 'collections/show' }
    end
  end

  def new
    @collection = Collection.new_locked_ldp_object(community_id: @community.id)
  end

  def create
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

  def edit; end

  def update
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.update(permitted_attributes(Collection))
        redirect_to admin_community_collection_path(@community, @collection), notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      if unlocked_collection.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
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
