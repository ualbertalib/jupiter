class ApplicationController < ActionController::Base

  include Pundit::Authorization

  before_action :store_user_location!, if: :storable_location?
  after_action :verify_authorized, except: [:service_unavailable]

  helper_method :current_announcements, :current_user, :read_only_mode_enabled?, :logins_enabled?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from JupiterCore::ObjectNotFound,
              ActiveRecord::RecordNotFound,
              ActionController::RoutingError, with: :render_404

  rescue_from JupiterCore::SolrBadRequestError, with: :render_400

  rescue_from ActionController::Redirecting::UnsafeRedirectError do
    redirect_to root_url
  end

  before_action :set_paper_trail_whodunnit

  def service_unavailable
    head :service_unavailable, 'Retry-After' => 24.hours
  end

  protected

  def storable_location?
    request.get? && !request.xhr? && request.fullpath.exclude?('auth')
  end

  def store_user_location!
    session[:previous_user_location] = request.fullpath
  end

  # Returns the current logged-in user (if any).
  def current_user
    return nil if read_only_mode_enabled?

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
    return if user.blank?
    return if read_only_mode_enabled?

    @current_user = user
    session[:user_id] = user.id
    UpdateUserActivityJob.perform_now(@current_user.id,
                                      Time.now.utc.to_s,
                                      request.remote_ip,
                                      sign_in: true)
  end

  # Logs out the current user.
  def log_off_user
    session.delete(:user_id)
    @current_user = nil
  end

  def user_not_authorized
    if current_user.present?
      flash[:alert] = t('authorization.user_not_authorized')
      redirect_back_or_to(root_path)
    else
      session[:forwarding_url] = request.fullpath if request.get?
      redirect_to root_url, alert: t('authorization.user_not_authorized_try_logging_in')
    end
  end

  def render_404(exception = nil)
    raise exception if exception && Rails.env.development?

    respond_to do |format|
      format.html do
        render file: Rails.public_path.join('404.html'), layout: false, status: :not_found
      end
      format.js { render json: '', status: :not_found, content_type: 'application/json' }
      format.any { head :not_found }
    end
  end

  def render_400(exception = nil)
    raise exception if exception && Rails.env.development?

    respond_to do |format|
      format.html do
        render file: Rails.public_path.join('400.html'), layout: false, status: :bad_request
      end
      format.js { render json: '', status: :bad_request, content_type: 'application/json' }
      format.any { head :bad_request }
    end
  end

  def redirect_back_to
    redirect_to(session.delete(:forwarding_url) || session.delete(:previous_user_location) || root_path)
  end

  def current_announcements
    Announcement.current
  end

  def read_only_mode_enabled?
    Rails.cache.fetch('read_only_mode.first.enabled', expires_in: 1.minute) do
      ReadOnlyMode.first.enabled
    end
  end

  def logins_enabled?
    !read_only_mode_enabled?
  end

end
