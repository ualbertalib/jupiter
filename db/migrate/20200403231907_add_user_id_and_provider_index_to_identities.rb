class AddUserIdAndProviderIndexToIdentities < ActiveRecord::Migration[6.0]
  def change
    add_index :identities, [:user_id, :provider], unique: true
  end
end
