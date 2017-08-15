class Admin::DashboardController < Admin::AdminController

  def index
    @works = Work.all # TODO: LockedLDPObject has no concept of limits? Needs to solr this?
    @users = User.limit(10) # TODO: Ordered by last_sign_in_at once implemented
  end

end
