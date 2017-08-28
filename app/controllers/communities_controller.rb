class CommunitiesController < ApplicationController

  before_action -> { authorize :application, :admin? }, except: [:index, :show]

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
    @community =
      Community.new_locked_ldp_object(permitted_attributes(Community)
                                       .merge(owner: current_user&.id))
    authorize @community
    @community.unlock_and_fetch_ldp_object(&:save!)

    # TODO: success flash message?
    redirect_to @community
  end

  def update
    @community = Community.find(params[:id])
    authorize @community
    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      unlocked_community.update!(permitted_attributes(Community))
    end
    flash[:notice] = t('.updated')
    redirect_to @community
  end

  def destroy
    community = Community.find(params[:id])
    authorize community
    community.unlock_and_fetch_ldp_object do |uo|
      if uo.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = t('.not_empty_error')
      end

      redirect_to admin_communities_and_collections_path
    end
  end

end
