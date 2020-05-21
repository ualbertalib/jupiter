class ProfileController < ApplicationController

  def index
    authorize :user, :logged_in?
    @user = current_user
    @draft_items = @user.draft_items.unpublished
    @draft_theses = @user.draft_theses.unpublished

    search_query_index = SearchQueryIndexService.new(
      base_restriction_key: Item.solr_exporter_class.solr_name_for(:owner, role: :exact_match),
      value: @user.id,
      params: params,
      current_user: current_user
    )
    @results = search_query_index.results
    @search_models = search_query_index.search_models
  end

end
