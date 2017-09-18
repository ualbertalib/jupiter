class Admin::CommunitiesController < Admin::AdminController

  def index
    @communities = Community.all
  end

  def show
    @community = Community.find(params[:id])
    respond_to do |format|
      format.js
      format.html { render template: 'communities/show' }
    end
  end

  def new
    @community = Community.new_locked_ldp_object
    authorize @community
  end

  def edit
    @community = Community.find(params[:id])
    authorize @community
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

  def update
    @community = Community.find(params[:id])

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
    community = Community.find(params[:id])
    community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
      end

      redirect_to admin_communities_path
    end
  end

end
