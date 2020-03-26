class AddApiKeyDigestAndSystemToUser < ActiveRecord::Migration[6.0]

  def change
    change_table :users, bulk: true do |t|
      t.string :api_key_digest, null: true
      t.boolean :system, default: false, null: false
    end
  end

end
