module ItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6
  QUERY_MAX = 500

  included do
    helper_method :results
    helper_method :search_models
  end

  attr_reader :results
  attr_reader :search_models

  def search_query_results(base_restriction_key: nil, value: nil, search_models: [Item, Thesis])
    raise ArgumentError, 'Must supply both a key and value' if base_restriction_key.present? && value.blank?

    @search_models = search_models

    # cut this off at a reasonable maximum to avoid DOSing Solr with truly huge queries (I managed to shove upwards
    # of 5000 characters in here locally)
    query = search_params[:search].truncate(QUERY_MAX) if search_params[:search].present?

    facets = search_params[:facets] || {}
    facets[base_restriction_key] = [value] if base_restriction_key.present?

    search_options = { q: query, models: search_models, as: current_user,
                       facets: facets, ranges: search_params[:ranges] }

    # sort by relelvance if a search term is present and no explicit sort field has been chosen
    sort_field = search_params[:sort]
    sort_field ||= :relevance if query.present?

    @results = JupiterCore::Search.faceted_search(search_options)
                                  .sort(sort_field, search_params[:direction])
                                  .page(search_params[:page])
  end

  private

  def search_params
    r = {}
    f = {}
    search_models.each do |model|
      model.solr_exporter_class.ranges.each do |range|
        next unless params[:ranges].present? && params[:ranges][range].present?

        if validate_range(params[:ranges][range])
          r[range] = [:begin, :end]
        else
          params[:ranges].delete(range)
        end
      end
      model.solr_exporter_class.facets.each do |facet|
        f[facet] = []
      end
    end
    params.permit(:community_id, :id, :tab, :page, :search, :sort, :direction, { facets: f }, ranges: r)
  end

  def validate_range(range)
    start = range[:begin]
    finish = range[:end]
    return true if start.match?(/\A\d{1,4}\z/) && finish.match?(/\A\d{1,4}\z/) && (start.to_i <= finish.to_i)

    flash[:alert] = "#{start} to #{finish} is not a valid range"
    false
  end
end
