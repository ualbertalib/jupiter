class Admin::UsersController < Admin::AdminController

  include ItemSearch

  before_action :fetch_user, only: [:show,
                                    :suspend,
                                    :unsuspend,
                                    :grant_admin,
                                    :revoke_admin,
                                    :login_as_user]

  def results
    super.sort(params[:sort] || :sort_year, params[:direction] || :desc)
  end

  def index
    @search = User.ransack(params[:q])
    @search.sorts = 'last_seen_at desc' if @search.sorts.empty?

    # Postgres treats nulls first in an ordered list, lets reverse this behaviour.
    result = @search.result
    orders = result.arel.orders.map do |order|
      order.direction == :asc ? "#{order.to_sql} NULLS FIRST" : "#{order.to_sql} NULLS LAST"
    end
    result = result.except(:order).order(Arel.sql(orders.join(', '))) if orders.count > 0

    @users = result.page(params[:page])
  end

  def show
    restrict_items_to(Item.solr_name_for(:owner, role: :exact_match), @user.id)
    @draft_items = @user.draft_items.unpublished
    @draft_theses = @user.draft_theses.unpublished
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

end
