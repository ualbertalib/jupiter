module ItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6

  private

  def item_search_setup(base_query = nil)
    @max_facets = MAX_FACETS
    query = if base_query.present?
              [base_query]
            else
              []
            end
    query.append(params[:query]) if params[:query].present?
    options = { q: query, models: [Item, Thesis], as: current_user }
    options[:facets] = params[:facets]
    # Make sure selected facets and solr-only authors/subjects appear first in facet list
    @first_facet_categories = (params[:facets]&.keys || []) + ['all_contributors_sim', 'all_subjects_sim']
    @results = JupiterCore::Search.faceted_search(options)
    @results.sort(sort_column, sort_direction).page params[:page]
  end
end
