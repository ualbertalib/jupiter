class Admin::DashboardController < Admin::AdminController

  def index
    @works = Work.all # TODO: AF has no concept of limits? Needs to solr this?
    @users = User.limit(10)
  end

end
