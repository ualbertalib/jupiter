class Admin::UsersController < Admin::AdminController

  AUTOCOMPLETE_LIMIT = 50

  helper_method :user_sort_column, :sort_direction

  before_action :fetch_user, only: [:show,
                                    :suspend,
                                    :unsuspend,
                                    :grant_admin,
                                    :revoke_admin,
                                    :impersonate]

  def index
    # TODO: Add filters for admin/suspended/active/no items etc?
    @users = User.search(params[:query]).order("#{user_sort_column} #{sort_direction}").page params[:page]
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

  def impersonate
    authorize [:admin, @user]

    session[:impersonator_id] = current_user.id

    sign_in(@user)

    logger.info("Admin '#{current_user.name}' has started impersonating '#{@user.name}'")

    # TODO: goes to users dashboard once implemented
    redirect_to root_path, notice: t('admin.users.show.impersonate_flash', user: @user.name)
  end

  def autocomplete
    return render(json: '') unless params[:query].present?
    render json: User.search(params[:query]).limit(AUTOCOMPLETE_LIMIT)
                     .map { |user|
                       # send URL and an attibute that combines name/email with each hit
                       { url: admin_user_path(user), name_email: "#{user.name} (#{user.email})" }
                     }
  end

  private

  def fetch_user
    @user = User.find(params[:id])
  end

  def user_sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : 'email'
  end

  # TODO: Should be record_created_at?
  def item_sort_column
    ['title', 'date_created'].include?(params[:sort]) ? params[:sort] : 'date_created'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end
