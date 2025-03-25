class AddReadOnlyToItemsThesesAndCollections < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :read_only, :boolean, default: false
    add_column :theses, :read_only, :boolean, default: false
    add_column :collections, :read_only, :boolean, default: false
  end
end
