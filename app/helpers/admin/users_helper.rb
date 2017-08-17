module Admin::UsersHelper
  def sortable(column, title = nil)
    title ||= column.titleize

    font_awesome_icon = if column == sort_column
                          "sort-#{sort_direction}"
                        else
                          'sort'
                        end

    direction = if column == sort_column && sort_direction == 'asc'
                  'desc'
                else
                  'asc'
                end

    link_to "#{title} #{fa_icon font_awesome_icon}".html_safe,
            params: { query: params[:query], sort: column, direction: direction }
  end
end
