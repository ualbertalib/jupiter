require 'test_helper'
require 'capybara/poltergeist' if ENV['CAPYBARA_PHANTOMJS']

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  if ENV['CAPYBARA_PHANTOMJS']
    driven_by :poltergeist, screen_size: [1920, 6000]
  else
    # Set options if you have a special selenium url (like if your running selenium in a docker container)
    # Otherwise just use the defaults by providing empty hash
    options = ENV['SELENIUM_URL'].present? ? { url: ENV['SELENIUM_URL'] } : {}

    driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: options
  end

  def setup
    if ENV['CAPYBARA_PHANTOMJS']
      # Click to user menu fails sometimes. This advice helps:
      # https://github.com/mattheworiordan/capybara-screenshot/issues/154#issuecomment-288174420
      page.driver.restart if defined?(page.driver.restart)
    end

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
