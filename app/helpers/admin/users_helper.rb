module Admin::UsersHelper
  def items_sort_link(column, sort, title = nil)
    title ||= "#{column} #{sort}"
    klass = 'dropdown-item'
    klass += ' active' if params[:sort] == column && params[:direction] == sort

    link_to title, { params: { sort: column, direction: sort } }, class: klass
  end

  # html_safe is used securely in the next two methods
  def user_role(user)
    if user.admin?
      "<span class='user-admin'>#{icon('fas', 'shield-alt')} #{t('admin.users.admin_role')}</span>".html_safe
    else
      t('admin.users.user_role')
    end
  end

  def user_status(user)
    if user.suspended?
      "<span class='user-suspended'>#{icon('fas', 'ban')} #{t('admin.users.suspended_status')}</span>".html_safe
    else
      t('admin.users.active_status')
    end
  end
end
