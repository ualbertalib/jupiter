module CollectionItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6

  included do
    before_action :item_search_setup, only: :show
  end

  private

  def item_search_setup
    @max_facets = MAX_FACETS
    query = ["member_of_paths_dpsim:#{@collection.path}"]
    query.append(params[:query]) if params[:query].present?
    options = { q: query, models: [Item], as: current_user }
    options[:facets] = params[:facets]
    @results = JupiterCore::Search.faceted_search(options)
    @results.sort(sort_column, sort_direction).page params[:page]
  end
end
