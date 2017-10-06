class Admin::CommunitiesController < Admin::AdminController

  before_action :fetch_community, only: [:show, :edit, :update, :destroy]

  def index
    # anybody have a better idea for doing this? Lame to have to litter it everywhere
    params[:facets].permit! if params[:facets].present?
    # Populate via search, so that admins can facet
    @communities = JupiterCore::Search.faceted_search(facets: params[:facets], models: Community, as: current_user)
    @communities.page params[:page]
  end

  def show
    respond_to do |format|
      format.js
      format.html { render template: 'communities/show' }
    end
  end

  def new
    @community = Community.new_locked_ldp_object
  end

  def create
    @community =
      Community.new_locked_ldp_object(permitted_attributes(Community)
                                       .merge(owner: current_user&.id))

    if params[:community][:logo].present?
      @community.logo.attach(params[:community][:logo])
    end

    @community.unlock_and_fetch_ldp_object do |unlocked_community|
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
      # Note: monkey patch to ActiveStorage removes any previous versions
      @community.logo.attach(params[:community][:logo])
    end

    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.update(permitted_attributes(Community))
        redirect_to [:admin, @community], notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
      end

      redirect_to admin_communities_path
    end
  end

  private

  def fetch_community
    @community = Community.find(params[:id])
  end

end
