module PaginateAndSortMethods
  extend ActiveSupport::Concern

  private

  def sort_column(columns: ['title', 'record_created_at'], default: 'title')
    columns.include?(params[:sort]) ? params[:sort] : default
  end

  def sort_direction(default: 'asc')
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : default
  end
end
