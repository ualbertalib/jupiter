class ProfileController < ApplicationController

  include ItemSearch

  before_action :ensure_logged_in

  def index
    @user = current_user
    item_search_setup(Item.search_term_for(:owner, @user.id, role: :exact_match))
  end

  private

  def ensure_logged_in
    authorize :user, :logged_in?
  end

end
