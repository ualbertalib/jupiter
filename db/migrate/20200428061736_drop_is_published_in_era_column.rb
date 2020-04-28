class DropIsPublishedInEraColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :draft_items, :is_published_in_era
    remove_column :draft_theses, :is_published_in_era
  end
end
