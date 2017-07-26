class ApplicationController < ActionController::Base

  include Pundit

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Returns the current logged-in user (if any).
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # Let views be able to access current_user
  helper_method :current_user

  # Signs in the given user.
  def sign_in(user)
    @current_user = user
    session[:user_id] = user.try(:id)
  end

  # Logs out the current user.
  def log_off_user
    session[:user_id] = nil
    @current_user = nil
  end

  def user_not_authorized
    # TODO: should actually redirect to login page, then after login, redirects back
    flash[:alert] = I18n.t('authorization.user_not_authorized')
    redirect_to(request.referrer || root_path)
  end

end
