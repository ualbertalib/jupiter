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
    Sidekiq::Worker.clear_all
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

  def locked_ldp_fixture(class_name, fixture_name)
    find_or_create_locked_ldp_fixture(class_name, fixture_name)
  end

  # uses :title as a lookup so must be unique
  # TODO: it would be groovy if this could do
  # @item, @community, @collection = find_or_create_locked_ldp_fixture(Item, :item_with_collection_and_community_dependencies)
  def find_or_create_locked_ldp_fixture(class_name, fixture_name)
    fixtures = YAML.safe_load(ERB.new(
      File.read(Rails.root.join('test', 'ldp_fixtures', "#{class_name.to_s.underscore}.yml"))
    ).result).symbolize_keys!
    options = fixtures[fixture_name]
    options = resolve_fixture_dependencies(options)
    class_name.where(title: options[:title]).first || class_name.new_locked_ldp_object(options)
  end

  def resolve_fixture_dependencies(options)
    options.slice('Collection', 'Community', 'Item').each do |class_name, fixture_name|
      object = find_or_create_locked_ldp_fixture(class_name.constantize, fixture_name.to_sym)
      options[class_name.underscore + '_id'] = object.id
      options.delete(class_name)
    end
    options
  end

  # turn on test mode for omniauth
  OmniAuth.config.test_mode = true

end
