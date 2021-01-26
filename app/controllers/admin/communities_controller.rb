class Admin::CommunitiesController < Admin::AdminController

  before_action :fetch_community, only: [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html do
        @communities = Community.order(Community.sort_order(params)).page params[:page]
        @title = t('.header')
        render template: 'communities/index'
      end
      format.json do
        community_title_index = Community.solr_exporter_class.solr_name_for(:title, role: :search)
        collection_title_index = Collection.solr_exporter_class.solr_name_for(:title, role: :search)
        @communities = JupiterCore::Search.faceted_search(q: "#{community_title_index}:#{params[:search]}*",
                                                          models: [Community],
                                                          as: current_user)
                                          .sort(:title, :asc).limit(5)
        @collections = JupiterCore::Search.faceted_search(q: "#{collection_title_index}:#{params[:search]}*",
                                                          models: [Collection],
                                                          as: current_user)
                                          .sort(:community_title, :asc)
                                          .sort(:title, :asc).limit(5)
      end
    end
  end

  def show
    respond_to do |format|
      format.js do
        # Used for the collapsable dropdown to show member collections
        @collections = @community.member_collections.order(Collection.sort_order(params))
        render template: 'communities/show'
      end
      format.html do
        @collections = @community.member_collections.order(Collection.sort_order(params)).page params[:page]
        render template: 'communities/show'
      end
    end
  end

  def new
    @community = Community.new
  end

  def create
    @community =
      Community.new(permitted_attributes(Community)
                                       .merge(owner_id: current_user&.id))

    @community.logo.attach(params[:community][:logo]) if params[:community][:logo].present?

    @community.tap do |unlocked_community|
      if unlocked_community.save
        redirect_to [:admin, @community], notice: t('.created')
      else
        render :new, status: :bad_request
      end
    end
  end

  def edit; end

  def update
    if params[:community][:logo].present?
      # NOTE: monkey patch to ActiveStorage removes any previous versions
      @community.logo.attach(params[:community][:logo])
    end

    @community.tap do |unlocked_community|
      if unlocked_community.update(permitted_attributes(Community))
        redirect_to [:admin, @community], notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @community.tap do |unlocked_community|
      if unlocked_community.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = unlocked_community.errors.full_messages.first
      end

      redirect_to admin_communities_path
    end
  end

  private

  def fetch_community
    @community = Community.find(params[:id])
  end

end
