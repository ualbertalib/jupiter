class AddSystemAccountIfNeeded < ActiveRecord::Migration[6.0]
  def up    

    unless User.find_by(email: 'ditech@ualberta.ca').blank?
      User.create ({
        name: 'System user',
        email: 'ditech@ualberta.ca',
        admin: false,
        password_digest: BCrypt::Password.create(
          Rails.application.secrets.system_user_password
        )
      })
    end
  end

  def down; end
end
