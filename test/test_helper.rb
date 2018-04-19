require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require File.expand_path('../../config/environment', __FILE__)
require 'active_fedora/cleaner'
require 'minitest/hooks/test'
require 'minitest/mock'
require 'rails/test_help'
require 'sidekiq/testing'
require 'vcr'
require 'webmock/minitest'
require 'shoulda/matchers'

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr'
  config.hook_into :webmock

  # Only want VCR to intercept requests to external URLs.
  config.ignore_localhost = true
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

  include Minitest::Hooks
  # clean ActiveFedora at the end of all tests in a given test class
  def after_all # this is minitest-hooks
    super
    ActiveFedora::Cleaner.clean!
    keys = Redis.current.keys("#{Rails.configuration.redis_key_prefix}*")
    Redis.current.del(keys) if keys.present?
    Sidekiq::Worker.clear_all
  end

  # Add more helper methods to be used by all tests here...

  # give this gibberish method a more semantically meaningful name for test-readers
  def generate_random_string
    Haikunator.haikunate
  end

  def freeze_time(&block)
    travel_to Time.current, &block
  end

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
