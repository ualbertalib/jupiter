class UpdateUserActivityJob < ApplicationJob
  queue_as :default

  def perform(current_user_id, now, last_ip_address, sign_in: false)
    raise InvalidParameter, :now unless now.present?
    raise InvalidParameter, :current_user_id unless current_user_id.present?
    raise InvalidParameter, :last_ip_address unless last_ip_address.present?

    current_user = User.find_by(id: current_user_id)
    current_user.update_activity!(last_ip_address, now, sign_in: sign_in)
  end

end
