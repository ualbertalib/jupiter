require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  teardown do
    Rails.application.env_config['omniauth.auth'] = nil
  end

  test 'new session page' do
    get login_url
    assert_response :success
  end

  context '#create' do
    context 'with valid new user' do
      should 'create a new user and new identity' do
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
        assert_equal 'John Doe', user.display_name
        assert_equal 'johndoe@ualberta.ca', user.email
        assert_equal 'saml', identity.provider
        assert_equal 'johndoe', identity.uid
        assert_redirected_to root_url
        assert_equal I18n.t('login.success', kind: 'saml'), flash[:notice]
        assert logged_in?
      end
    end

    context 'with valid existing user' do
      should 'use existing identity if present' do
        user = users(:user)
        identity = identities(:user_saml)

        OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
          provider: 'saml',
          uid: identity.uid,
          info: { email: user.email, name: user.display_name }
        )

        assert_no_difference ['User.count', 'Identity.count'] do
          post '/auth/saml/callback'
        end

        assert_redirected_to root_url
        assert_equal I18n.t('login.success', kind: 'saml'), flash[:notice]
        assert logged_in?
      end

      should 'create a new identity if not present' do
        user = users(:user)

        Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
          provider: 'twitter',
          uid: 'twitter-012345',
          info: { email: user.email, name: user.display_name }
        )

        assert_no_difference ['User.count'] do
          post '/auth/twitter/callback'
        end

        identity = user.identities.last
        assert_equal 'twitter', identity.provider
        assert_equal 'twitter-012345', identity.uid

        assert_redirected_to root_url
        assert_equal I18n.t('login.success', kind: 'twitter'), flash[:notice]
        assert logged_in?
      end
    end

    context 'with invalid new user' do
      should 'give an error message and not save the user' do
        OmniAuth.config.mock_auth[:saml] = :invalid_credentials

        assert_no_difference ['User.count', 'Identity.count'] do
          post '/auth/saml/callback'
        end

        assert_redirected_to login_url
        assert_equal I18n.t('login.error'), flash[:alert]
        assert_not logged_in?
      end
    end
  end

  test 'session destroy' do
    user = users(:user)

    sign_in_as user

    assert logged_in?

    get logout_url
    assert_redirected_to root_url
    assert_equal I18n.t('session.destroy.signed_out'), flash[:notice]

    assert_not logged_in?
  end

  test 'session omniauth failure' do
    get auth_failure_url
    assert_redirected_to login_url
    assert_equal I18n.t('login.error'), flash[:alert]
  end

end
