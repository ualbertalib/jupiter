class AddApiToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :api, :boolean, null: false, default: false
  end
end
