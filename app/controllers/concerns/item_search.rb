module ItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6

  included do
    helper_method :results
  end

  private

  def restrict_items_to(base_restriction_key = nil, val = nil)
    raise ArgumentError, 'Must supply both a key and value' if base_restriction_key.present? && val.blank?

    @search_models = [Item, Thesis]

    facets = params[:facets] || {}
    facets[base_restriction_key] = [val] if base_restriction_key.present?

    options = { q: params[:search], models: @search_models, as: current_user, facets: facets }

    @results = JupiterCore::Search.faceted_search(options).sort(params[:sort], params[:direction]).page params[:page]
  end

  def results
    @results
  end
end
