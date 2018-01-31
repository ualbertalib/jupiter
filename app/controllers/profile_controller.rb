class ProfileController < ApplicationController

  include ItemSearch

  def index
    authorize :user, :logged_in?
    @user = current_user
    @draft_items = @user.draft_items.where(status: :active)

    item_search_setup(Item.search_term_for(:owner, @user.id, role: :exact_match))
  end

end
