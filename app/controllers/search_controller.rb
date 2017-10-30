class SearchController < ApplicationController

  MAX_FACETS = 6

  skip_after_action :verify_authorized

  def index
    params[:facets].permit! if params[:facets].present?

    @max_facets = MAX_FACETS
    @active_tab = params[:tab]&.to_sym || :item
    @results = {}

    # TODO: Likely we want to do one search and segregate the results by model
    [:item, :collection, :community].each do |model|
      # Only facet for the current tab or the result count will be wrong on the tab header
      options = { q: params[:search], models: model.to_s.classify.constantize, as: current_user }
      options[:facets] = params[:facets] if model == @active_tab
      @results[model] = JupiterCore::Search.faceted_search(options)
      # TODO: figure out sort -- @results[model].sort(:title, :asc).page params[:page]
      @results[model].page params[:page]
    end
  end

end
