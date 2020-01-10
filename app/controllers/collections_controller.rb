class CollectionsController < ApplicationController

  include ItemSearch

  before_action :fetch_and_authorize_community
  before_action :fetch_and_authorize_collection

  def show
    restrict_items_to(Item.solr_exporter_class.solr_name_for(:member_of_paths, role: :pathing), @collection.path)
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
