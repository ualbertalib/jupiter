class SessionsController < ApplicationController

  # some omniauth callbacks (like developer) are sent using a post request,
  # need to disable this otherwise session will be clobbered by rails
  # https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-openid-providers
  # TODO just limit this to development mode? since this doesnt effect saml?
  skip_before_action :verify_authenticity_token, only: [:create, :system_login]

  skip_after_action :verify_authorized

  def create
    auth_hash = request.env['omniauth.auth']

    # Do we have an existing user already?
    identity = Identity.find_by(provider: auth_hash.provider, uid: auth_hash.uid)

    # Attempt to grab the user if we do have an identity already
    user = identity.try(:user)

    # Couldn't grab a user, so must be a new user/identity, so lets create them
    if user.blank? && auth_hash.info.email.present? && auth_hash.info.name.present?
      user = User.find_by(email: auth_hash.info.email)

      if user.nil?
        user = User.create(email: auth_hash.info.email,
                           name: auth_hash.info.name)
      end

      user.identities.create(provider: auth_hash.provider, uid: auth_hash.uid)
    end

    return redirect_to root_path, alert: t('login.user_suspended') if user&.suspended?

    # Sign the user in, if they exist
    sign_in(user)

    if current_user.present?
      # Was signed in successfully, redirect them back to where they came from or to the homepage
      flash[:notice] = t('login.success')
      redirect_back_to
    else
      # Else something went wrong along the way with omniauth
      redirect_to root_path, alert: t('login.error')
    end
  end

  def destroy
    log_off_user
    redirect_to root_url, notice: t('.signed_out')
  end

  def failure
    redirect_to root_path, alert: t('login.error')
  end

  def logout_as_user
    admin_user = User.find(session[:admin_id])

    raise Pundit::NotAuthorizedError if !admin_user.admin? || admin_user.suspended?

    original_user = current_user
    sign_in(admin_user)
    logger.info("Admin '#{admin_user.name}' has now logged out as '#{original_user.name}'")

    session[:admin_id] = nil

    redirect_to admin_user_path(original_user), notice: t('.flash', original_user: original_user.name)
  end

  def system_login
    uid = params[:uid]
    password = params[:password]
    provider = 'system'.freeze
    identity = Identity.find_by(provider: provider, uid: uid)

    return head :unauthorized unless identity.present? &&
                                     identity.authenticate(password)

    user = identity.try(:user)
    return head :ok if sign_in(user)

    head :internal_server_error
  end

end
