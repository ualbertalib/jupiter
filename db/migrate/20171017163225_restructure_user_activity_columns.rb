class RestructureUserActivityColumns < ActiveRecord::Migration[5.1]
  def change
    # Sign in columns:
    # We keep last_sign_in_at/last_sign_in_ip, set to current time/ip on login
    # Avoid the word 'current', since this implies they are presently logged in (may not be so).
    remove_column :users, :current_sign_in_at, :datetime
    remove_column :users, :current_sign_in_ip, :string

    # previous_sign_in_at will store previous value of existing last_sign_in_at column (ditto for ip columns)
    add_column :users, :previous_sign_in_at, :datetime
    add_column :users, :previous_sign_in_ip, :string

    # Tracking recent activity (did they access a page in the last XXX minutes?)
    add_column :users, :last_seen_at, :datetime
    add_column :users, :last_seen_ip, :string
  end
end
