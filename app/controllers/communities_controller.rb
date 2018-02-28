class CommunitiesController < ApplicationController

  include CommunitiesCollectionsTypeahead

  def index
    authorize Community
    respond_to do |format|
      format.html do
        @communities = Community.sort(sort_column, sort_direction).page params[:page]
        @title = t('.header')
      end
      format.json do
        results = typeahead_results(params[:query])
        render json: { results: results }
      end
    end
  end

  def show
    @community = Community.find(params[:id])
    authorize @community
    respond_to do |format|
      format.html do
        @collections = @community.member_collections.sort(sort_column, sort_direction).page params[:page]
      end
      format.js do
        # Used for the collapsable dropdown to show member collections
        @collections = @community.member_collections.sort(sort_column, sort_direction)
      end

      format.json do
        # Used in item_draft.js
        collections = @community.member_collections
        collections = collections.select { |c| c.restricted.blank? } unless current_user.admin?
        render json: @community.attributes.merge(collections: collections)
      end
    end
  end

end
