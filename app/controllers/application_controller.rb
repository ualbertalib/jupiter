class ApplicationController < ActionController::Base

  include Pundit

  before_action :store_user_location!, if: :storable_location?
  after_action :verify_authorized, except: [:service_unavailable]

  helper_method :current_announcements, :current_user

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from JupiterCore::ObjectNotFound,
              ActiveRecord::RecordNotFound,
              ActionController::RoutingError, with: :render_404

  def service_unavailable
    head :service_unavailable, 'Retry-After' => 24.hours
  end

  protected

  def storable_location?
    request.get? && !request.xhr? && request.fullpath !~ /auth/
  end

  def store_user_location!
    session[:previous_user_location] = request.fullpath
  end

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

  # Signs in the given user.
  def sign_in(user)
    @current_user = user
    session[:user_id] = user.try(:id)

    # rubocop:disable Style/GuardClause
    if @current_user.present?
      UpdateUserActivityJob.perform_now(@current_user.id,
                                        Time.now.utc.to_s,
                                        request.remote_ip,
                                        sign_in: true)
    end
    # rubocop:enable Style/GuardClause
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
      redirect_to root_url, alert: t('authorization.user_not_authorized_try_logging_in')
    end
  end

  def render_404(exception = nil)
    raise exception if exception && Rails.env.development?

    respond_to do |format|
      format.html do
        render file: Rails.root.join('public/404.html'), layout: false, status: :not_found
      end
      format.js { render json: '', status: :not_found, content_type: 'application/json' }
      format.any { head :not_found }
    end
  end

  def redirect_back_to
    redirect_to session.delete(:forwarding_url) || session.delete(:previous_user_location) || root_path
  end

  def current_announcements
    Announcement.current
  end

end
