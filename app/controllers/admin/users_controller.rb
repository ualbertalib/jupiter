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
    @works = Work.all # TODO: need to get works off user somehow? like so:
    # @works = @user.works.order(:name).page params[:page]
  end

  def block
    authorize [:admin, @user]

    @user.blocked = true
    @user.save

    logger.info("Admin '#{current_user.display_name}' has blocked '#{@user.display_name}'")

    flash[:notice] = t('admin.users.show.block_flash')
    redirect_to admin_user_path(@user)
  end

  def unblock
    authorize [:admin, @user]

    @user.blocked = false
    @user.save

    logger.info("Admin '#{current_user.display_name}' has unblocked '#{@user.display_name}'")

    flash[:notice] = t('admin.users.show.unblock_flash')
    redirect_to admin_user_path(@user)
  end

  def grant_admin
    authorize [:admin, @user]

    @user.admin = true
    @user.save

    logger.info("Admin '#{current_user.display_name}' has granted admin access to '#{@user.display_name}'")

    flash[:notice] = t('admin.users.show.grant_admin_flash')
    redirect_to admin_user_path(@user)
  end

  def revoke_admin
    authorize [:admin, @user]

    @user.admin = false
    @user.save

    logger.info("Admin '#{current_user.display_name}' has revoked admin access from '#{@user.display_name}'")

    flash[:notice] = t('admin.users.show.revoke_admin_flash')
    redirect_to admin_user_path(@user)
  end

  def impersonate
    authorize [:admin, @user]

    session[:impersonator_id] = current_user.id

    sign_in(@user)

    logger.info("Admin '#{current_user.display_name}' has started impersonating '#{@user.display_name}'")

    flash[:notice] = t('admin.users.show.impersonate_flash', user: @user.display_name)

    redirect_to root_path
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
