class AddSuspendedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :suspended, :boolean, null: false, default: false
    rename_column :users, :display_name, :name
  end
end
