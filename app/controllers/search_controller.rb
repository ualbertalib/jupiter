class SearchController < ApplicationController

  include ItemSearch

  DEFAULT_TAB = 'item'.freeze

  skip_after_action :verify_authorized

  def index
    search_models = case (params[:tab] || DEFAULT_TAB)
                    when 'item'
                      [Item, Thesis]
                    when 'collection'
                      [Collection]
                    when 'community'
                      [Community]
                    else
                      return redirect_to search_path(tab: :item)
                    end

    search_query_results(search_models: search_models)

    respond_to do |format|
      format.html
      format.json { render json: results }
    end
  end

end
