class AdminConstraint

  def matches?(request)
    user = User.find_by(id: request.session[:user_id])
    user.present? && user.admin?
  end

end
