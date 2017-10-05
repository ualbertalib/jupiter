class CommunitiesController < ApplicationController

  def index
    authorize Community
    @communities = Community.all
  end

  def show
    @community = Community.find(params[:id])
    authorize @community
    respond_to do |format|
      format.html
      format.json do
        # Used in items.js
        render json: @community.member_collections
      end
    end
  end

end
