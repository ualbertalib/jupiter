module ItemSearch
  extend ActiveSupport::Concern

  # How many facets are shown before it says 'Show more ...'
  MAX_FACETS = 6

  private

  def item_search_setup(base_query = nil)
    query = if base_query.present?
              [base_query]
            else
              []
            end
    query.append(params[:search]) if params[:search].present?
    options = { q: query, models: [Item, Thesis], as: current_user }
    options[:facets] = params[:facets]
    # Make sure selected facets then solr-only authors/subjects appear first in facet list
    @first_facet_categories = (params[:facets]&.keys || []) +
                              [Item.solr_name_for(:all_contributors, role: :facet),
                               Item.solr_name_for(:all_subjects, role: :facet)]
    @results = JupiterCore::Search.faceted_search(options)
    @results.sort(sort_column, sort_direction).page params[:page]
    # Toggle that we want to be able to sort by sort_year
    @item_sort = true
  end

  def sort_column
    ['title', 'sort_year'].include?(params[:sort]) ? params[:sort] : 'title'
  end
end
