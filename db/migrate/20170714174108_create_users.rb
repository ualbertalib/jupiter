class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string   :email, null: false
      t.string   :display_name, null: false
      t.boolean  :admin, null: false, default: false

      # login stats columns
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip


      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
