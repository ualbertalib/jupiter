class ApplicationController < ActionController::Base

  include Pundit

  before_action :store_user_location!, if: :storable_location?
  after_action :verify_authorized

  protect_from_forgery with: :exception

  helper_method :current_announcements, :path_for_result

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from JupiterCore::ObjectNotFound,
              ActiveRecord::RecordNotFound,
              ActionController::RoutingError, with: :render_404

  protected

  def storable_location?
    request.get? && !request.xhr? && request.fullpath !~ /auth/
  end

  def store_user_location!
    uri = URI.parse(request.fullpath)
    return unless uri

    path = [uri.path.sub(/\A\/+/, '/'), uri.query].compact.join('?')
    path = [path, uri.fragment].compact.join('#')
    session[:previous_user_location] = path
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

  # Let views be able to access current_user
  helper_method :current_user

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
        render file: Rails.root.join('public', '404'), layout: false, status: :not_found
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

  def path_for_result(result)
    if result.is_a? Collection
      community_collection_path(result.community, result)
    elsif result.is_a? Thesis
      item_path(result)
    else
      polymorphic_path(result)
    end
  end

  def sort_column(columns: ['title', 'record_created_at'], default: 'title')
    columns.include?(params[:sort]) ? params[:sort] : default
  end

  def sort_direction(default: 'asc')
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : default
  end

end
