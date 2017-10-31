class Admin::DashboardController < Admin::AdminController

  def index
    @items = Item.limit(10).sort(:record_created_at, :desc)
    @users = User.limit(10).order(last_seen_at: :desc)
  end

end
