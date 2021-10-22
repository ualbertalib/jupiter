class PaginatingDecorator < Draper::CollectionDecorator

  delegate :arel, :current_page, :total_pages, :limit_value, :entry_name, :total_count, :offset_value, :last_page?

end
