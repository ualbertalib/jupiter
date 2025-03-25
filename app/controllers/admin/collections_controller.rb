class Admin::CollectionsController < Admin::AdminController

  before_action :fetch_community
  before_action :fetch_collection, only: [:show, :edit, :update, :destroy]

  def show
    search_query_index = UserSearchService.new(
      base_restriction_key: Item.solr_exporter_class.solr_name_for(:member_of_paths, role: :pathing),
      value: @collection.path,
      params:,
      current_user:
    )

    @results = search_query_index.results
    @search_models = search_query_index.search_models
    @collection = @collection.decorate

    respond_to do |format|
      format.html { render template: 'collections/show' }
    end
  end

  def new
    @collection = Collection.new(community_id: @community.id)
  end

  def edit
    return unless @collection.read_only?

    flash[:alert] = t('.read_only')
    redirect_to admin_community_collection_path(@community, @collection)
  end

  def create
    @collection =
      Collection.new(permitted_attributes(Collection)
                .merge(owner_id: current_user.id, community_id: @community.id))
    @collection.tap do |unlocked_collection|
      if unlocked_collection.save
        redirect_to admin_community_collection_path(@community, @collection), notice: t('.created')
      else
        render :new, status: :bad_request
      end
    end
  end

  def update
    @collection.tap do |unlocked_collection|
      if unlocked_collection.update(permitted_attributes(Collection))
        redirect_to admin_community_collection_path(@community, @collection), notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @collection.tap do |unlocked_collection|
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
