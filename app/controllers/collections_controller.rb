class CollectionsController < ApplicationController

  include ItemSearch

  before_action :fetch_and_authorize_community
  before_action :fetch_and_authorize_collection

  def show
    # TODO: could this solr-ness be hooked up to `search_term_for`?
    item_search_setup("member_of_paths_dpsim:#{@collection.path}")
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
