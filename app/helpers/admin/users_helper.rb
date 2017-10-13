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
    # The only param that is being consumed here is `params[:direction]` which is being sanitized by
    # the "sort_direction" method
    link_to "#{title} #{fa_icon font_awesome_icon}".html_safe, # rubocop:disable Rails/OutputSafety
            params: { query: params[:query],
                      sort: column, direction: direction }
  end

  def items_sort_link(column, sort, title = nil)
    title ||= "#{column} #{sort}"
    klass = 'dropdown-item'
    klass += ' active' if params[:sort] == column && params[:direction] == sort

    link_to title, { params: { sort: column, direction: sort } }, class: klass
  end

  # html_safe is used securely in the next two methods
  # rubocop:disable Rails/OutputSafety
  def user_role(user)
    if user.admin
      "<span class='user-admin'>#{fa_icon('shield')} #{t('admin.users.index.admin_role')}</span>".html_safe
    else
      t('admin.users.index.user_role')
    end
  end

  def user_status(user)
    if user.suspended
      "<span class='user-suspended'>#{fa_icon('ban')} #{t('admin.users.index.suspended_status')}</span>".html_safe
    else
      t('admin.users.index.active_status')
    end
  end
  # rubocop:enable Rails/OutputSafety
end
