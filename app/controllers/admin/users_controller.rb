class Admin::UsersController < Admin::AdminController

  helper_method :sort_column, :sort_direction

  before_action :fetch_user, only: [:show,
                                    :block,
                                    :unblock,
                                    :grant_admin,
                                    :revoke_admin,
                                    :impersonate]

  def index
    # filters for admin/blocked/active/no works etc?
    @users = User.search(params[:q]).order("#{sort_column} #{sort_direction}").page params[:page]
  end

  def show
    @works = Work.all # TODO: need to get works off user somehow?
    # @works = @user.works.order(:name).page params[:page]
  end

  # TODO: log all actions
  def block
    @user.blocked = true
    @user.save

    logger.info("Admin '#{current_user.display_name}' has blocked '#{@user.display_name}'")

    flash[:notice] = 'User has successfully been blocked'
    redirect_to admin_user_path(@user)
  end

  def unblock
    @user.blocked = false
    @user.save

    logger.info("Admin '#{current_user.display_name}' has unblocked '#{@user.display_name}'")

    flash[:notice] = 'User has successfully been unblocked'
    redirect_to admin_user_path(@user)
  end

  def grant_admin
    @user.admin = true
    @user.save

    logger.info("Admin '#{current_user.display_name}' has granted admin access to '#{@user.display_name}'")

    flash[:notice] = 'User has successfully been granted admin access'
    redirect_to admin_user_path(@user)
  end

  def revoke_admin
    @user.admin = false
    @user.save

    logger.info("Admin '#{current_user.display_name}' has revoked admin access from '#{@user.display_name}'")

    flash[:notice] = 'User has successfully been revoked admin access'
    redirect_to admin_user_path(@user)
  end

  def impersonate
    if !@user.blocked? && !@user.admin? && @user != current_user
      session[:impersonator_id] = current_user.id

      sign_in(@user)

      logger.info("Admin '#{current_user.display_name}' has started impersonating '#{@user.display_name}'")

      flash[:notice] = "You are now impersonating #{@user.display_name}"

      redirect_to root_path
    else
      flash[:alert] = 'You cannot impersonate a blocked user, an admin user or yourself'
      redirect_to admin_user_path(@user)
    end
  end

  private

  def fetch_user
    @user = User.find(params[:id])
  end

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : 'email'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end
