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
      current_user: current_user
    )
    @results = search_query_index.results
    @search_models = search_query_index.search_models

    respond_to do |format|
      format.html
      format.json { render json: @results }
    end
  end

end
