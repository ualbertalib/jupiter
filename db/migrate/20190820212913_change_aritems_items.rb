class ChangeAritemsItems < ActiveRecord::Migration[5.2]
  def change
    rename_table :ar_items, :items
  end
end
