class ApplicationController < ActionController::Base

  include Pundit

  after_action :verify_authorized

  protect_from_forgery with: :exception

  helper_method :current_announcements

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Returns the current logged-in user (if any).
  def current_user
    return @current_user if @current_user.present?
    @current_user = User.find_by(id: session[:user_id])

    return nil if @current_user.blank?

    if @current_user.suspended?
      log_off_user
      return redirect_to root_path, alert: t('login.user_suspended')
    end

    if @current_user.last_seen_at.blank? || @current_user.last_seen_at < 5.minutes.ago
      UpdateUserActivityJob.perform_later(@current_user.id, Time.now.utc.to_s, request.remote_ip)
    end

    @current_user
  end

  # Let views be able to access current_user
  helper_method :current_user

  # Signs in the given user.
  def sign_in(user)
    @current_user = user
    session[:user_id] = user.try(:id)
    UpdateUserActivityJob.perform_now(@current_user.id, Time.now.utc.to_s, request.remote_ip, sign_in: true)
  end

  # Logs out the current user.
  def log_off_user
    session.delete(:user_id)
    @current_user = nil
  end

  def user_not_authorized
    if current_user.present?
      flash[:alert] = t('authorization.user_not_authorized')

      # referer gets funky with omniauth and all the redirects it does,
      # so handle this sanely by ignoring any referer coming from omniauth (/auth/) path
      if request.referer && request.referer !~ /auth/
        redirect_to request.referer
      else
        redirect_to root_path
      end
    else
      session[:forwarding_url] = request.original_url if request.get?
      redirect_to login_url, alert: t('authorization.user_not_authorized_try_logging_in')
    end
  end

  def redirect_back_to
    redirect_to session[:forwarding_url] || root_path
    session.delete(:forwarding_url)
  end

  def current_announcements
    Announcement.current
  end

  def sort_column(columns: ['title', 'record_created_at'], default: 'title')
    columns.include?(params[:sort]) ? params[:sort] : default
  end

  def sort_direction(default: 'asc')
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : default
  end

end
