class SearchController < ApplicationController

  DEFAULT_TAB = 'item'.freeze

  skip_after_action :verify_authorized

  def index
    models = case (params[:tab] || DEFAULT_TAB)
             when 'item'
               [Item, Thesis]
             when 'collection'
               [Collection]
             when 'community'
               [Community]
             else
               return redirect_to search_path(tab: :item)
             end

    search_query_index = UserSearchService.new(
      search_models: models,
      params: params,
      current_user: current_user,
      fulltext: Flipper.enabled?(:fulltext_search, current_user)
    )
    @results = search_query_index.results
    @search_models = search_query_index.search_models
    flash.now[:alert] = t('search.invalid_date_range_flash') if search_query_index.invalid_date_range

    respond_to do |format|
      format.html
      format.json { render json: @results }
    end
  end

end
