class Admin::DashboardController < Admin::AdminController

  def index
    @works = Work.limit(10).sort(:date_created, :desc)
    @users = User.limit(10) # TODO: Ordered by last_sign_in_at once implemented
  end

end
