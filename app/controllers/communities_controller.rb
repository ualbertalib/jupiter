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
      redirect_to @community
  end

  def destroy
    community = Community.find(params[:id])
    community.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = 'Community deleted'
      else
        flash[:alert] = 'Cannot delete a non-empty Community'
      end

      redirect_to admin_communities_and_collections_path
    end
  end

  protected

  def community_params
    params[:community].permit(Community.attribute_names)
  end

end
