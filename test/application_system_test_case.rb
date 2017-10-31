require 'test_helper'
require 'selenium-webdriver'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  driver = if ENV['CAPYBARA_NO_HEADLESS']
             :selenium
           else
             :selenium_chrome_headless
           end

  # Set options if you have a special selenium url (like if your running selenium in a docker container)
  # Otherwise just use the defaults by providing empty hash
  options = ENV['SELENIUM_URL'].present? ? { url: ENV['SELENIUM_URL'] } : {}
  driven_by driver, using: :chrome, screen_size: [1400, 1400], options: options

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

  def logout_user
    visit logout_url
  end

end
