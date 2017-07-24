require 'application_system_test_case'

class AuthenticationTest < ApplicationSystemTestCase

  context 'User logs in and logs out' do
    should 'work with correct credentials' do
      visit root_url

      click_on I18n.t('application.navbar.links.login')
      assert_selector 'h1', text: I18n.t('sessions.new.header')

      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
        provider: 'saml',
        uid: 'johndoe',
        info: {
          email: 'johndoe@ualberta.ca',
          name: 'John Doe'
        }
      )

      click_link I18n.t('sessions.new.button_text')

      assert_text I18n.t('omniauth.success', kind: 'saml')

      assert_text 'John Doe'

      click_link 'John Doe' # opens user dropdown which has the logout link

      click_link I18n.t('application.navbar.links.logout')

      assert_text I18n.t('omniauth.signed_out')
      assert_selector 'a', text: I18n.t('application.navbar.links.login')
    end

    should 'not work with bad credentials' do
      visit root_url

      click_on I18n.t('application.navbar.links.login')
      assert_selector 'h1', text: I18n.t('sessions.new.header')

      OmniAuth.config.mock_auth[:saml] = :invalid_credentials

      click_link I18n.t('sessions.new.button_text')

      assert_text I18n.t('omniauth.error')

      assert_selector 'a', text: I18n.t('application.navbar.links.login')
    end
  end

  # TODO: add test for protected page, should prompt for login, then take you back to original page

end
