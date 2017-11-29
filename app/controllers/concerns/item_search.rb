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
    options = { q: query, models: [Item], as: current_user }
    options[:facets] = params[:facets]
    @results = JupiterCore::Search.faceted_search(options)
    @results.sort(sort_column, sort_direction).page params[:page]
  end
end
