require 'test_helper'
require 'selenium-webdriver'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  if ENV['CAPYBARA_NO_HEADLESS']
    # Set options if you have a special selenium url (like if your running selenium in a docker container)
    # Otherwise just use the defaults by providing empty hash
    options = ENV['SELENIUM_URL'].present? ? { url: ENV['SELENIUM_URL'] } : {}
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: options
  else
    driven_by :selenium_chrome_headless
  end

  def setup
    host! "http://#{IPSocket.getaddress(Socket.gethostname)}"
    super
  end

  # Logs in a test user. Used for system tests.
  def login_user(user)
    identity = user.identities.first

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] =
        OmniAuth::AuthHash.new(provider: identity.provider,
                               uid: identity.uid)

    visit root_url

    click_on I18n.t('application.navbar.links.login')
  end

  def logout_user
    visit logout_url
  end

end
