module Admin::UsersHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    font_awesome_icon = column == sort_column ? "sort-#{sort_direction}" : 'sort'
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'

    link_to "#{title} #{fa_icon font_awesome_icon}".html_safe,
            params: { query: params[:query], sort: column, direction: direction }
  end
end
