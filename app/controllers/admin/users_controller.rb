class Admin::UsersController < Admin::AdminController

  before_action :fetch_user, only: [:show,
                                    :suspend,
                                    :unsuspend,
                                    :grant_admin,
                                    :revoke_admin,
                                    :login_as_user]

  def index
    @search = User.ransack(params[:q])
    @search.sorts = 'last_seen_at desc' if @search.sorts.empty?

    @users = @search.result.page(params[:page])
  end

  def show
    @items = @user.items
    @items = @items.sort(item_sort_column, sort_direction) if item_sort_column && sort_direction
    @items = @items.page params[:page]
  end

  def suspend
    authorize [:admin, @user]

    @user.suspended = true
    @user.save

    logger.info("Admin '#{current_user.name}' has suspended '#{@user.name}'")

    redirect_to admin_user_path(@user), notice: t('admin.users.show.suspend_flash')
  end

  def unsuspend
    authorize [:admin, @user]

    @user.suspended = false
    @user.save

    logger.info("Admin '#{current_user.name}' has unsuspended '#{@user.name}'")

    redirect_to admin_user_path(@user), notice: t('admin.users.show.unsuspend_flash')
  end

  def grant_admin
    authorize [:admin, @user]

    @user.admin = true
    @user.save

    logger.info("Admin '#{current_user.name}' has granted admin access to '#{@user.name}'")

    redirect_to admin_user_path(@user), notice: t('admin.users.show.grant_admin_flash')
  end

  def revoke_admin
    authorize [:admin, @user]

    @user.admin = false
    @user.save

    logger.info("Admin '#{current_user.name}' has revoked admin access from '#{@user.name}'")

    redirect_to admin_user_path(@user), notice: t('admin.users.show.revoke_admin_flash')
  end

  def login_as_user
    authorize [:admin, @user]

    session[:admin_id] = current_user.id

    sign_in(@user)

    logger.info("Admin '#{current_user.name}' has now logged in as'#{@user.name}'")

    # TODO: goes to users dashboard once implemented
    redirect_to root_path, notice: t('admin.users.show.login_as_user_flash', user: @user.name)
  end

  private

  def fetch_user
    @user = User.find(params[:id])
  end

  def item_sort_column
    ['title', 'record_created_at'].include?(params[:sort]) ? params[:sort] : 'record_created_at'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'desc'
  end

end
