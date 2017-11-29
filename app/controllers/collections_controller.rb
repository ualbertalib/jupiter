class CollectionsController < ApplicationController

  before_action :fetch_and_authorize_community
  before_action :fetch_and_authorize_collection

  # Collection must be fetched before we include this ...
  include CollectionItemSearch

  def show; end

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
