class SearchController < ApplicationController

  QUERY_MAX = 500
  MAX_FACETS = 6

  skip_after_action :verify_authorized

  def index
    params[:facets].permit! if params[:facets].present?

    # cut this off at a reasonable maximum to avoid DOSing Solr with truly huge queries (I managed to shove upwards
    # of 5000 characters in here locally)
    query = params[:search].truncate(QUERY_MAX) if params[:search].present?

    @max_facets = MAX_FACETS
    @active_tab = params[:tab]&.to_sym || :item
    @results = {}

    # Make sure selected facets and solr-only authors/subjects appear first in facet list
    @first_facet_categories = params[:facets]&.keys || []
    if @active_tab == :item
      @first_facet_categories += [Item.solr_name_for(:all_contributors, role: :facet),
                                  Item.solr_name_for(:all_subjects, role: :facet)]
    end

    # TODO: Likely we want to do one search and segregate the results by model
    # TODO: Check performance of this when we have more objects in use
    [:item, :collection, :community].each do |model|
      # Only facet for the current tab or the result count will be wrong on the tab header
      models = if model == :item
                 [Item, Thesis]
               else
                 model.to_s.classify.constantize
               end

      options = { q: query, models: models, as: current_user }
      options[:facets] = params[:facets] if model == @active_tab
      @results[model] = JupiterCore::Search.faceted_search(options)
    end
    # Toggle that we want to be able to sort by sort_year
    if @active_tab == :item
      @item_sort = true
      @results[@active_tab].sort(sort_column(columns: ['title', 'sort_year']), sort_direction).page params[:page]
    else
      @results[@active_tab].sort(sort_column, sort_direction).page params[:page]
    end
  end

end
