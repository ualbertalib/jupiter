class CollectionsController < ApplicationController

  before_action :fetch_and_authorize_community
  before_action :fetch_and_authorize_collection

  def show
    search_query_index = UserSearchService.new(
      base_restriction_key: Item.solr_exporter_class.solr_name_for(:member_of_paths, role: :pathing),
      value: @collection.path,
      params: params,
      current_user: current_user
    )
    @results = search_query_index.results
    @search_models = search_query_index.search_models
  end

  private

  def fetch_and_authorize_community
    @community = Community.find(params[:community_id])
    authorize @community
  end

  def fetch_and_authorize_collection
    @collection = Collection.find(params[:id])
    authorize @collection
  end

end
