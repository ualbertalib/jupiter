class Admin::DashboardController < Admin::AdminController

  def index
    @works = Work.limit(10) # .sort('date_created, order: :asc') fixed in matts PR: #66,
    @users = User.limit(10) # TODO: Ordered by last_sign_in_at once implemented
  end

end
