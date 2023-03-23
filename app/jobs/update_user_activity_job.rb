class UpdateUserActivityJob < ApplicationJob

  queue_as :default

  def perform(current_user_id, now, last_ip_address, sign_in: false)
    raise ArgumentError, :now if now.blank?
    raise ArgumentError, :current_user_id if current_user_id.blank?
    raise ArgumentError, :last_ip_address if last_ip_address.blank?

    current_user = User.find_by(id: current_user_id)
    current_user.update_activity!(now, last_ip_address, sign_in: sign_in)
  end

end
