module Admin::UsersHelper
  FILTER_MAP = { all: :all,
                 admin: 'admin.users.admin_role',
                 user: 'admin.users.user_role',
                 suspended: 'admin.users.suspended_status',
                 active: 'admin.users.active_status' }.freeze

  def user_filter_choices
    FILTER_MAP.map { |k, v| [t(v), k] }
  end

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
            { params: { query: params[:query], filter: params[:filter], sort: column, direction: direction } },
            remote: true
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
      "<span class='user-admin'>#{fa_icon('shield')} #{t('admin.users.admin_role')}</span>".html_safe
    else
      t('admin.users.user_role')
    end
  end

  def user_status(user)
    if user.suspended
      "<span class='user-suspended'>#{fa_icon('ban')} #{t('admin.users.suspended_status')}</span>".html_safe
    else
      t('admin.users.active_status')
    end
  end
  # rubocop:enable Rails/OutputSafety
end
