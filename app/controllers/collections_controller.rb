class CollectionsController < ApplicationController

  def show
    @collection = Collection.find(params[:id])
    authorize @collection
    @community = Community.find(@collection.community_id)
    authorize @community
  end

end
