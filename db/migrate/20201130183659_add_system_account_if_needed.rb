class AddSystemAccountIfNeeded < ActiveRecord::Migration[5.2]
  def change
    User.find_or_create_by(email: 'ditech@ualberta.ca') do |user|
      user.name ||= 'System user'
      user.admin = false
    end
  end
end
