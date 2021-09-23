require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    Rails.application.env_config['omniauth.auth'] = nil
  end

  test 'should create a new user and new identity' do
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
      provider: 'saml',
      uid: 'johndoe',
      info: { email: 'johndoe@ualberta.ca', name: 'John Doe' }
    )
    assert_difference ['User.count', 'Identity.count'], 1 do
      post '/auth/saml/callback'
    end

    user = User.last
    identity = user.identities.last
    assert_equal 'John Doe', user.name
    assert_equal 'johndoe@ualberta.ca', user.email
    assert_equal 'saml', identity.provider
    assert_equal 'johndoe', identity.uid
    assert_redirected_to root_url
    assert_equal I18n.t('login.success'), flash[:notice]
    assert logged_in?
  end

  test 'should use existing identity if present' do
    user = users(:user_regular)
    identity = identities(:identity_user_saml)

    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
      provider: 'saml',
      uid: identity.uid,
      info: { email: user.email, name: user.name }
    )

    assert_no_difference ['User.count', 'Identity.count'] do
      post '/auth/saml/callback'
    end

    assert_redirected_to root_url
    assert_equal I18n.t('login.success'), flash[:notice]
    assert logged_in?
  end

  test 'should create a new identity if not present' do
    user = users(:user_regular)

    Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'twitter',
      uid: 'twitter-012345',
      info: { email: user.email, name: user.name }
    )

    assert_difference('Identity.count', 1) do
      post '/auth/twitter/callback'
    end

    identity = user.identities.last
    assert_equal 'twitter', identity.provider
    assert_equal 'twitter-012345', identity.uid

    assert_redirected_to root_url
    assert_equal I18n.t('login.success'), flash[:notice]
    assert logged_in?
  end

  test 'should give an error message and not save the user with invalid new user' do
    OmniAuth.config.mock_auth[:saml] = :invalid_credentials

    assert_no_difference ['User.count', 'Identity.count'] do
      post '/auth/saml/callback'
    end

    assert_redirected_to root_url
    assert_equal I18n.t('login.error'), flash[:alert]
    assert_not logged_in?
  end

  test 'should give an error message and user is not logged in with a suspended user' do
    user = users(:user_suspended)

    Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'twitter',
      uid: 'twitter-012345',
      info: { email: user.email, name: user.name }
    )

    assert_difference('Identity.count', 1) do
      post '/auth/twitter/callback'
    end

    identity = user.identities.last
    assert_equal 'twitter', identity.provider
    assert_equal 'twitter-012345', identity.uid

    assert_redirected_to root_path
    assert_equal I18n.t('login.user_suspended'), flash[:alert]
    assert_not logged_in?
  end

  test 'should handle session destroying aka logout properly' do
    user = users(:user_regular)

    sign_in_as user

    assert logged_in?

    get logout_url
    assert_redirected_to root_url
    assert_equal I18n.t('sessions.destroy.signed_out'), flash[:notice]

    assert_not logged_in?
  end

  test 'should return properly flash message on a omniauth failure' do
    get auth_failure_url
    assert_redirected_to root_url
    assert_equal I18n.t('login.error'), flash[:alert]
  end

  test 'should logout as user, login as admin and redirect to user show page' do
    user = users(:user_regular)
    admin = users(:user_admin)

    # login as user as admin
    sign_in_as admin

    post login_as_user_admin_user_url(user)

    assert_redirected_to root_url
    assert_equal I18n.t('admin.users.show.login_as_user_flash', user: user.name), flash[:notice]

    assert_equal session[:user_id], user.id
    assert_equal session[:admin_id], admin.id

    # logout_as_user and return back to admin
    post logout_as_user_url

    assert_redirected_to admin_user_url(user)
    assert_equal I18n.t('sessions.logout_as_user.flash', original_user: user.name), flash[:notice]

    assert_equal session[:user_id], admin.id
    assert_nil session[:admin_id]
  end

  test 'should log in as local system account' do
    user = users(:user_system)
    post auth_system_url, params: {
      email: 'ditech@ualberta.ca',
      api_key: '3eeb395e-63b7-11ea-bc55-0242ac130003'
    }

    assert_equal user.id, session[:user_id]
    assert_response :success
  end

  test 'should not log in as a system account with new omniauth identity' do
    Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'twitter',
      uid: 'twitter-012345',
      # The ditech@ualberta.ca email would come from authentication provider
      # and we know that it is a system account
      info: { email: 'ditech@ualberta.ca', name: 'Twitter user name' }
    )
    post '/auth/twitter/callback'

    assert_redirected_to root_path
    assert_equal I18n.t('login.error'), flash[:alert]
    assert_not logged_in?
  end

  test 'should not log in from a saml account that is system' do
    user = users(:user_system)
    sign_in_as user

    assert_redirected_to root_path
    assert_equal I18n.t('login.error'), flash[:alert]
    assert_not logged_in?
  end

  test 'should not log in if api_key is incorrect' do
    post auth_system_url, params: {
      email: 'ditech@ualberta.ca',
      api_key: '2eeb395e-63b7-11ea-bc55-0242ac130003'
    }

    # Receive unauthorized response
    assert_response 401
  end

end
