require 'test_helper'
require 'selenium-webdriver'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  if ENV['CAPYBARA_NO_HEADLESS']
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
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
