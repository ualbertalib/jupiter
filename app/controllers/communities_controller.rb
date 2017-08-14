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

end
