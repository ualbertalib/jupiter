require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { url: 'http://chrome:4444/wd/hub' }

  def setup
    host! "http://#{IPSocket.getaddress(Socket.gethostname)}"
    super
  end

  # Logs in a test user. Used for system tests.
  def login_as_user(user)
    identity = user.identities.first

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] =
        OmniAuth::AuthHash.new(provider: identity.provider,
                               uid: identity.uid)

    visit root_url

    click_on I18n.t('application.navbar.links.login')
    assert_selector 'h1', text: I18n.t('sessions.new.header')

    click_link I18n.t('sessions.new.saml_link')
  end

end
