class SearchController < ApplicationController

  QUERY_MAX = 500
  DEFAULT_TAB = 'item'.freeze

  skip_after_action :verify_authorized
  helper_method :results

  def index
    # note that search_params depends on @search_models being an array, so we need to establish this first
    @search_models = case (params[:tab] || DEFAULT_TAB)
                     when 'item'
                       [Item, Thesis]
                     when 'collection'
                       [Collection]
                     when 'community'
                       [Community]
                     else
                       return redirect_to search_path(tab: :item)
                     end

    # cut this off at a reasonable maximum to avoid DOSing Solr with truly huge queries (I managed to shove upwards
    # of 5000 characters in here locally)
    query = search_params[:search].truncate(QUERY_MAX) if search_params[:search].present?

    search_opts = { q: query, models: @search_models, as: current_user,
                    facets: search_params[:facets], ranges: search_params[:ranges] }

    # sort by relelvance if a search term is present and no explicit sort field has been chosen
    sort_field = search_params[:sort]
    sort_field ||= :relevance if query.present?

    @results = JupiterCore::Search.faceted_search(search_opts)
                                  .sort(sort_field, search_params[:direction])
                                  .page(search_params[:page])
  end

  attr_reader :results

  private

  def search_params
    r = {}
    f = {}
    @search_models.each do |model|
      model.ranges.each do |range|
        next unless params[:ranges].present? && params[:ranges][range].present?
        if validate_range(params[:ranges][range])
          r[range] = [:begin, :end]
        else
          params[:ranges].delete(range)
        end
      end
      model.facets.each do |facet|
        f[facet] = []
      end
    end
    params.permit(:tab, :page, :search, :sort, :direction, { facets: f }, ranges: r)
  end

  def validate_range(range)
    start = range[:begin]
    finish = range[:end]
    return true if start.match?(/\A\d{1,4}\z/) && finish.match?(/\A\d{1,4}\z/) && (start.to_i <= finish.to_i)
    flash[:alert] = "#{start} to #{finish} is not a valid range"
    false
  end

end
