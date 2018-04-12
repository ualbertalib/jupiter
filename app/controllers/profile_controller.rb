class ProfileController < ApplicationController

  include ItemSearch

  def index
    authorize :user, :logged_in?
    @user = current_user
    @draft_items = @user.draft_items.unpublished

    restrict_items_to(Item.solr_name_for(:owner, role: :exact_match), @user.id)
  end

end
