class AddPasswordDigestToIdentity < ActiveRecord::Migration[6.0]
  def change
    add_column :identities, :password_digest, :string, null: false, default: ''
  end
end
