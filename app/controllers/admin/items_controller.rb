class Admin::ItemsController < Admin::AdminController

  include ItemSearch

  def index
    item_search_setup
  end

  def destroy
    @item = JupiterCore::LockedLdpObject.find(params[:id], types: [Item, Thesis])
    begin
      @item.unlock_and_fetch_ldp_object(&:destroy!)
      flash[:notice] = t('.deleted')
    rescue StandardError => e
      flash[:alert] = t('.failed')
      Rollbar.error("Error deleting #{@item.id}", e)
    end

    redirect_back(fallback_location: root_path)
  end

end
