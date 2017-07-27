class Admin::CommunitiesAndCollectionsController < Admin::AdminController

  def index
    @communities = Community.all
  end

  def show
    @community = Community.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def new; end

  def create; end

end
