require 'application_system_test_case'

class AuthenticationTest < ApplicationSystemTestCase

  context 'User logs in and logs out' do
    should 'work with correct credentials' do
      visit root_url

      click_on I18n.t('application.navbar.links.login')
      assert_selector 'h1', text: I18n.t('sessions.new.header')

      Rails.application.env_config['omniauth.auth'] =
        OmniAuth.config.mock_auth[:saml] =
          OmniAuth::AuthHash.new(
            provider: 'saml',
            uid: 'johndoe',
            info: {
              email: 'johndoe@ualberta.ca',
              name: 'John Doe'
            }
          )

      click_link I18n.t('sessions.new.saml_link')

      assert_text I18n.t('login.success', kind: 'saml')

      assert_text 'John Doe'

      click_link 'John Doe' # opens user dropdown which has the logout link

      click_link I18n.t('application.navbar.links.logout')

      assert_text I18n.t('sessions.destroy.signed_out')
      assert_selector 'a', text: I18n.t('application.navbar.links.login')
    end

    should 'not work with bad credentials' do
      visit root_url

      click_on I18n.t('application.navbar.links.login')
      assert_selector 'h1', text: I18n.t('sessions.new.header')

      Rails.application.env_config['omniauth.auth'] =
        OmniAuth.config.mock_auth[:saml] = :invalid_credentials

      click_link I18n.t('sessions.new.saml_link')

      assert_text I18n.t('login.error')

      assert_selector 'a', text: I18n.t('application.navbar.links.login')
    end
  end

  context 'when visiting a protected page' do
    should 'get redirected to login then back to page, if user is authorized' do
      visit profile_url

      assert_text I18n.t('authorization.user_not_authorized_try_logging_in')
      assert_selector 'h1', text: I18n.t('sessions.new.header')

      Rails.application.env_config['omniauth.auth'] =
        OmniAuth.config.mock_auth[:saml] =
          OmniAuth::AuthHash.new(
            provider: 'saml',
            uid: 'johndoe',
            info: {
              email: 'johndoe@ualberta.ca',
              name: 'John Doe'
            }
          )

      click_link I18n.t('sessions.new.saml_link')

      assert_text I18n.t('login.success', kind: 'saml')

      # TODO: fix this view and i18n this
      assert_text I18n.t('admin.users.created')
    end

    # TODO: Nothing currently exist to nicely test this behaviour, Comment this out for time being
    # Once user dashboards or something is implemented we can renable this test
    #
    # should 'get redirected to login then back to login page with error, if user is unauthorized' do
    #   visit 'TODO visit url that you need special permission' # only admins can do this

    #   assert_text I18n.t('authorization.user_not_authorized_try_logging_in')
    #   assert_selector 'h1', text: I18n.t('sessions.new.header')

    #   Rails.application.env_config['omniauth.auth'] =
    #     OmniAuth.config.mock_auth[:saml] =
    #       OmniAuth::AuthHash.new(
    #         provider: 'saml',
    #         uid: 'johndoe',
    #         info: {
    #           email: 'johndoe@ualberta.ca',
    #           name: 'John Doe'
    #         }
    #       )

    #   click_link I18n.t('sessions.new.saml_link')

    #   assert_text I18n.t('authorization.user_not_authorized')

    #   assert_selector 'h1', text: I18n.t('sessions.new.header')
    # end
  end

end
