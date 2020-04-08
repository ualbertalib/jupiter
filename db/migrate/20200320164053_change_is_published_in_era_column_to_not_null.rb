class ChangeIsPublishedInEraColumnToNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :draft_items, :is_published_in_era, false, false
    change_column_null :draft_theses, :is_published_in_era, false, false
  end
end
