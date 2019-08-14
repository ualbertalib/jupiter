class AddIsEraPublishedColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :draft_items, :is_published_in_era, :boolean, default: false, index: true
    add_column :draft_theses, :is_published_in_era, :boolean, default: false, index: true
    add_column :draft_collections, :is_published_in_era, :boolean, default: false, index: true
    add_column :draft_communities, :is_published_in_era, :boolean, default: false, index: true
  end
end
