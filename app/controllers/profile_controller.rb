class ProfileController < ApplicationController

  include ItemSearch

  def index
    authorize :user, :logged_in?
    @user = current_user
    @draft_items = @user.draft_items.unpublished
    @draft_theses = @user.draft_theses.unpublished
    search_query_results(
      base_restriction_key: Item.solr_exporter_class.solr_name_for(:owner, role: :exact_match),
      value: @user.id
    )
  end

end
