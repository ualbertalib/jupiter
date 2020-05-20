class Admin::ItemsController < Admin::AdminController

  include ItemSearch

  def index
    # no restrictions on items searched for
    search_query_results
  end

  def destroy
    @item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end

    begin
      @item.destroy!
      flash[:notice] = t('.deleted')
    rescue StandardError => e
      flash[:alert] = t('.failed')
      Rollbar.error("Error deleting #{@item.id}", e)
    end

    redirect_back(fallback_location: root_path)
  end

end
