require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require File.expand_path('../config/environment', __dir__)
require 'minitest/mock'
require 'rails/test_help'
require 'sidekiq/testing'
require 'vcr'
require 'webmock/minitest'

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr'
  config.hook_into :webmock

  # Only want VCR to intercept requests to external URLs.
  config.ignore_localhost = true

  # Allow drivers to download though webdrivers gem https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
  driver_urls = Webdrivers::Common.subclasses.map do |driver|
    Addressable::URI.parse(driver.base_url).host
  end
  config.ignore_hosts(*driver_urls)
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :active_record
    with.library :active_model
  end
end

# just push all jobs to an array for verification
Sidekiq::Testing.fake!

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # give this gibberish method a more semantically meaningful name for test-readers
  def generate_random_string
    Haikunator.haikunate
  end

  def teardown
    # Clear our solr index after every test run.
    # TODO: Maybe should look into this and only clear it out for tests that are actually testing against solr
    JupiterCore::SolrServices::Client.instance.truncate_index
  end

  # Add more helper methods to be used by all tests here...

  # Logs in a test user. Used for integration tests.
  def sign_in_as(user)
    # grab first user identitiy, dont care just need to login user
    identity = user.identities.first

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[identity.provider.to_sym] =
        OmniAuth::AuthHash.new(provider: identity.provider,
                               uid: identity.uid)

    post login_url(provider: identity.provider)
  end

  def sign_in_as_system_user
    user = users(:system_user)
    api_key = '3eeb395e-63b7-11ea-bc55-0242ac130003'
    post auth_system_url, params: { email: user.email, api_key: api_key }
  end

  # Returns true if a test user is logged in.
  def logged_in?
    session[:user_id].present?
  end

  # turn on test mode for omniauth
  OmniAuth.config.test_mode = true

end

class ActionDispatch::IntegrationTest

  def setup
    host! 'era.lvh.me'
    default_url_options[:host] = 'era.lvh.me'
  end

end
