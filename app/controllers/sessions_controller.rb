class SessionsController < ApplicationController

  # some omniauth callbacks (like developer) are sent using a post request,
  # need to disable this otherwise session will be clobbered by rails
  # https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-openid-providers
  # TODO just limit this to development mode? since this doesnt effect saml?
  skip_before_action :verify_authenticity_token, only: :create

  skip_after_action :verify_authorized, only: [:new, :create, :destroy, :failure]

  def new
    # renders login page (views/sessions/new.html.erb)
  end

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

    if user && user.suspended?
      return redirect_to login_path, alert: t('login.user_suspended')
    end

    # Sign the user in, if they exist
    sign_in(user)

    if current_user.present?
      # Was signed in successfully, redirect them back to where they came from or to the homepage
      flash[:notice] = t('login.success', kind: auth_hash.provider)
      redirect_back_to
    else
      # Else something went wrong along the way with omniauth
      redirect_to login_path, alert: t('login.error')
    end
  end

  def destroy
    log_off_user
    redirect_to root_url, notice: t('.signed_out')
  end

  def failure
    redirect_to login_path, alert: t('login.error')
  end

  def reverse_impersonate
    impersonator = User.find(session[:impersonator_id])

    authorize impersonator

    original_user = current_user
    sign_in(impersonator)
    logger.info("Admin '#{impersonator.name}' has stopped impersonating '#{original_user.name}'")

    session[:impersonator_id] = nil

    redirect_to admin_user_path(original_user), notice: t('.flash', original_user: original_user.name)
  end

end
