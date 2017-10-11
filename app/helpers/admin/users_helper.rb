module Admin::UsersHelper
  def sortable(column, title = nil)
    title ||= column.titleize

    font_awesome_icon = if column == user_sort_column
                          "sort-#{sort_direction}"
                        else
                          'sort'
                        end

    direction = if column == user_sort_column && sort_direction == 'asc'
                  'desc'
                else
                  'asc'
                end

    # html_safe is used securely here
    # The only param that is being consumed here is `params[:direction]` which is being sanitized by the "sort_direction" method
    link_to "#{title} #{fa_icon font_awesome_icon}".html_safe, # rubocop:disable Rails/OutputSafety
            { params: { query: params[:query],
                      sort: column, direction: direction }}, remote: true
  end

  def items_sort_link(column, sort, title = nil)
    title ||= "#{column} #{sort}"
    klass = 'dropdown-item'
    klass += ' active' if params[:sort] == column && params[:direction] == sort

    link_to title, { params: { sort: column, direction: sort } }, class: klass
  end

  def user_role(user)
    user.admin ? t('admin.users.admin_role') : t('admin.users.user_role')
  end

  def user_status(user)
    user.suspended ? t('admin.users.suspended_status') : t('admin.users.active_status')
  end
end
