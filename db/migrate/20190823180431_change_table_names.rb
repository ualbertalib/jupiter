class ChangeTableNames < ActiveRecord::Migration[5.2]
  def change
    rename_table :ar_items, :items
    rename_table :ar_theses, :theses
    rename_table :ar_communities, :communities
    rename_table :ar_collections, :collections
  end
end
