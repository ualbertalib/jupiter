class SearchController < ApplicationController

  skip_after_action :verify_authorized

  def index
    params[:facets].permit! if params[:facets].present?

    @results = JupiterCore::Search.faceted_search(q: params[:search], facets: params[:facets],
                                                  models: [Item, Collection, Community], as: current_user)
    @results.sort(:title, :asc).page params[:page]
  end

end
