class CommunitiesController < ApplicationController

  def show
    @community = Community.find(params[:id])
    authorize @community
    respond_to do |format|
      format.html
      format.json { render json: @community.member_collections }
    end
  end

  def index
    authorize Community
    @communities = Community.all
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
    @community = Community.new_locked_ldp_object(permitted_attributes(Community))
    authorize @community
    @community.unlock_and_fetch_ldp_object(&:save!)

    redirect_to @community
  end

  def update
    @community = Community.find(params[:id])
    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      unlocked_community.update!(community_params)
    end
    flash[:notice] = I18n.t('application.communities.updated')
    redirect_to @community
  end

  def destroy
    community = Community.find(params[:id])
    authorize community
    community.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = I18n.t('application.communities.deleted')
      else
        flash[:alert] = I18n.t('application.communities.not_empty_error')
      end

      redirect_to admin_communities_and_collections_path
    end
  end

  protected

  def community_params
    params[:community].permit(Community.attribute_names)
  end

end
