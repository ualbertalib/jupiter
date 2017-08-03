class Admin::UsersController < Admin::AdminController

  helper_method :sort_column, :sort_direction

  before_action :fetch_user, only: [:show,
                                    :block,
                                    :unblock,
                                    :grant_admin,
                                    :revoke_admin,
                                    :impersonate]

  skip_before_action :ensure_admin, only: [:reverse_impersonate]
  skip_after_action :verify_authorized, only: [:reverse_impersonate]

  def index
    # filters for admin/blocked/active/no works etc?
    @users = User.search(params[:q]).order("#{sort_column} #{sort_direction}").page params[:page]
    @users_count = User.count
  end

  def show
    @works = Work.all # TODO: need to get works off user somehow?
    # @works = @user.works.order(:name).page params[:page]
  end

  # TODO: log all actions
  def block
    @user.blocked = true
    @user.save
    flash[:notice] = 'User has successfully been blocked'
    redirect_to admin_user_path(@user)
  end

  def unblock
    @user.blocked = false
    @user.save
    flash[:notice] = 'User has successfully been unblocked'
    redirect_to admin_user_path(@user)
  end

  def grant_admin
    @user.admin = true
    @user.save
    flash[:notice] = 'User has successfully been granted admin access'
    redirect_to admin_user_path(@user)
  end

  def revoke_admin
    @user.admin = false
    @user.save
    flash[:notice] = 'User has successfully been revoked admin access'
    redirect_to admin_user_path(@user)
  end

  def impersonate
    if !@user.blocked? || !@user.admin?
      session[:impersonator_id] = current_user.id

      sign_in(@user)

      # Gitlab::AppLogger.info("User #{current_user.display_name} has started impersonating #{@user.display_name}")

      flash[:notice] = "You are now impersonating #{@user.display_name}"

      redirect_to root_path
    else
      flash[:alert] = 'You cannot impersonate a blocked user or another admin'
      redirect_to admin_user_path(user)
    end
  end

  def reverse_impersonate
    impersonator = User.find(session[:impersonator_id]) if session[:impersonator_id]

    return if impersonator.blank? && !impersonator.admin? && impersonator.blocked?

    original_user = current_user
    sign_in(impersonator)

    # Gitlab::AppLogger.info("User #{impersonator.display_name} has stopped impersonating #{original_user.display_name}")

    session[:impersonator_id] = nil
    flash[:notice] = "You are no longer impersonating #{original_user.display_name}"

    redirect_to admin_user_path(original_user)
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
