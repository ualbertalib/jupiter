module ItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6

  private

  def restrict_items_to(base_restriction_key = nil, val = nil)
    raise ArgumentError, 'Must supply both a key and value' if base_restriction_key.present? && !val.present?
    @search_models = [Item, Thesis]

    facets = params[:facets] || {}
    facets.merge(base_restriction_key => [val]) if base_restriction_key.present?

    options = { q: params[:search], models: @search_models, as: current_user, facets: facets }

    @results = JupiterCore::Search.faceted_search(options)
    @results.sort(sort_column, sort_direction).page params[:page]
  end

  def sort_column
    ['title', 'sort_year'].include?(params[:sort]) ? params[:sort] : 'title'
  end
end
