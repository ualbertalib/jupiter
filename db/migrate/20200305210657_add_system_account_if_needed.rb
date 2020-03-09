class AddSystemAccountIfNeeded < ActiveRecord::Migration[6.0]

  def up
    user = User.find_or_create_by email: 'ditech@ualberta.ca'
    user.name ||= 'System user'
    user.admin = false
    user.password_digest = BCrypt::Password.create(
      Rails.application.secrets.system_user_password
    )
    user.save
  end
  # We are not defining a down method because we are assuming that our system
  # user may exist before our migration. Our safest approach is to provide a
  # password that the system expects and leave the rest the same without
  # compromising the security of the system user.

end
