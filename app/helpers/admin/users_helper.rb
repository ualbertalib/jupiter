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

    link_to "#{title} #{fa_icon font_awesome_icon}".html_safe,
            params: { query: params[:query], sort: column, direction: direction }
  end

  def works_sort_link(column, sort, title = nil)
    title ||= "#{column} #{sort}"
    klass = 'dropdown-item'
    klass += ' active' if params[:sort] == column && params[:direction] == sort

    link_to title, { params: { sort: column, direction: sort } }, class: klass
  end
end
