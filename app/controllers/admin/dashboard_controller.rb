class Admin::DashboardController < Admin::AdminController

  def index
    @items = Item.limit(10).sort(:date_created, :desc) # TODO: Should use record_created_at?
    @users = User.limit(10) # TODO: Ordered by last_sign_in_at once implemented
  end

end
