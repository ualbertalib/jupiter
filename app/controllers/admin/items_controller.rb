class Admin::ItemsController < Admin::AdminController

  def index
    # no restrictions on items searched for
    search_query_index = UserSearchService.new(params:, current_user:)
    @results = search_query_index.results
    @search_models = search_query_index.search_models
  end

  def destroy
    @item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end

    if @item.read_only?
      flash[:alert] = t('items.edit.read_only')
      return redirect_to item_path @item
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

  def reset_doi
    item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end

    item.handle_doi_states
    redirect_back(fallback_location: :root)
  end

end
