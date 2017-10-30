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
      @results[model].sort(sort_column, sort_direction).page params[:page]
    end
  end

  private

  def sort_column
    ['title', 'record_created_at'].include?(params[:sort]) ? params[:sort] : 'title'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end
