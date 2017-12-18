class CollectionsController < ApplicationController

  include ItemSearch

  before_action :fetch_and_authorize_community
  before_action :fetch_and_authorize_collection

  def show
    item_search_setup(Item.search_term_for(:member_of_paths, @collection.path, role: :pathing))
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
