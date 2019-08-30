class Admin::DashboardController < Admin::AdminController

  def index
    @items = Item.limit(10).order(record_created_at: :desc)
    @users = User.where.not(last_seen_at: nil).limit(10).order(last_seen_at: :desc)
  end

end
