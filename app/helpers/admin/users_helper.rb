module Admin::UsersHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    font_awesome_icon = column == sort_column ? "sort-#{sort_direction}" : 'sort'
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'

    link_to params: { page: params[:page], q: params[:q], sort: column, direction: direction } do
      title fa_icon font_awesome_icon
    end
  end
end
