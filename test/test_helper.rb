require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/hooks/test'
require 'minitest/mock'
require 'active_fedora/cleaner'
require 'shoulda'
require 'webmock/minitest'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures/vcr'
  config.hook_into :webmock

  # Only want VCR to intercept requests to external URLs.
  config.ignore_localhost = true
end

class ActiveSupport::TestCase

  def freeze_time(&block)
    travel_to Time.current, &block
  end

  include Minitest::Hooks
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # give this gibberish method a more semantically meaningful name for test-readers
  def generate_random_string
    Haikunator.haikunate
  end

  # clean ActiveFedora at the end of all tests in a given test class
  def after_all
    super
    ActiveFedora::Cleaner.clean!
    keys = Redis.current.keys("#{Rails.configuration.redis_key_prefix}*")
    Redis.current.del(keys) if keys.present?
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

    post "/auth/#{identity.provider}/callback"
  end

  # Returns true if a test user is logged in.
  def logged_in?
    session[:user_id].present?
  end

  # turn on test mode for omniauth
  OmniAuth.config.test_mode = true

end
