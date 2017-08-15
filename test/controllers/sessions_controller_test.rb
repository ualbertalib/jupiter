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
        assert_equal 'John Doe', user.name
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
        user = users(:regular_user)
        identity = identities(:user_saml)

        OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
          provider: 'saml',
          uid: identity.uid,
          info: { email: user.email, name: user.name }
        )

        assert_no_difference ['User.count', 'Identity.count'] do
          post '/auth/saml/callback'
        end

        assert_redirected_to root_url
        assert_equal I18n.t('login.success', kind: 'saml'), flash[:notice]
        assert logged_in?
      end

      should 'create a new identity if not present' do
        user = users(:regular_user)

        Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
          provider: 'twitter',
          uid: 'twitter-012345',
          info: { email: user.email, name: user.name }
        )

        assert_difference ['Identity.count'], 1 do
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

    context 'with a suspended user' do
      should 'give an error message and user is not logged in' do
        user = users(:suspended_user)

        Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
          provider: 'twitter',
          uid: 'twitter-012345',
          info: { email: user.email, name: user.name }
        )

        assert_difference ['Identity.count'] do
          post '/auth/twitter/callback'
        end

        identity = user.identities.last
        assert_equal 'twitter', identity.provider
        assert_equal 'twitter-012345', identity.uid

        assert_redirected_to login_path
        assert_equal I18n.t('login.user_suspended'), flash[:alert]
        refute logged_in?
      end
    end
  end

  should 'handle session destroying aka logout properly' do
    user = users(:regular_user)

    sign_in_as user

    assert logged_in?

    get logout_url
    assert_redirected_to root_url
    assert_equal I18n.t('sessions.destroy.signed_out'), flash[:notice]

    assert_not logged_in?
  end

  should 'return properly flash message on a omniauth failure' do
    get auth_failure_url
    assert_redirected_to login_url
    assert_equal I18n.t('login.error'), flash[:alert]
  end

  context '#stop_impersonating' do
    should 'log admin back in and redirect to user show page' do
      user = users(:regular_user)
      admin = users(:admin)

      # impersonate user as admin
      sign_in_as admin

      post impersonate_admin_user_url(user)

      assert_redirected_to root_url
      assert_equal I18n.t('admin.users.show.impersonate_flash', user: user.name), flash[:notice]

      assert_equal session[:user_id], user.id
      assert_equal session[:impersonator_id], admin.id

      # stop impersonating and return back to admin
      post stop_impersonating_url

      assert_redirected_to admin_user_url(user)
      assert_equal I18n.t('sessions.stop_impersonating.flash', original_user: user.name), flash[:notice]

      assert_equal session[:user_id], admin.id
      assert_nil session[:impersonator_id]
    end
  end

end
