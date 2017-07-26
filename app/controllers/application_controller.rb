class ApplicationController < ActionController::Base

  include Pundit

  after_action :verify_authorized

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
    session.delete(:user_id)
    @current_user = nil
  end

  def user_not_authorized
    if current_user.present?
      flash[:alert] = I18n.t('authorization.user_not_authorized')
      redirect_to root_path
    else
      session[:forwarding_url] = request.original_url if request.get?
      flash[:alert] = I18n.t('authorization.user_not_authorized_try_logging_in')
      redirect_to login_url
    end
  end

  def redirect_back_to
    redirect_to session[:forwarding_url] || root_path
    session.delete(:forwarding_url)
  end

  def current_site_notifications
    SiteNotification.current
  end

end
