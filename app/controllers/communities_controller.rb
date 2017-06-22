class CommunitiesController < ApplicationController

  def show
    @community = Community.find(params[:id])
    respond_to do |format|
      format.html
      format.json {render json: @community.member_collections}
    end
  end

  def index
    @communities = Community.all
  end

  def new
    @community = Community.new_locked_ldp_object
  end

  def create
    @community = Community.new_locked_ldp_object(community_params)
    @community.unlock_and_load_writable_ldp_object.save!
    redirect_to @community
  end

  protected

  def community_params
    params[:community].permit(Community.attribute_names)
  end

end