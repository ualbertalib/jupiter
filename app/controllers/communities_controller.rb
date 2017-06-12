class CommunitiesController < ApplicationController

  def show
    @community = Community.find(params[:id])
  end

  def index
    @communities = Community.all
  end

  def new
    @community = Community.new
  end

  def create
    @community = Community.create!(community_params)
    redirect_to @community
  end

  protected

  def community_params
    params[:community].permit(Community.property_names)
  end

end