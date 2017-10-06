class Admin::DashboardController < Admin::AdminController

  def index
    @items = Item.limit(10) # Default order: record_created_at (desc)
    @users = User.limit(10) # TODO: Ordered by last_sign_in_at once implemented
  end

end
