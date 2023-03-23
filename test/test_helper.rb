require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require File.expand_path('../config/environment', __dir__)
require 'minitest/mock'
require 'rails/test_help'
require 'sidekiq/testing'
require 'vcr'
require 'webmock/minitest'
require 'minitest/retry'
# rubocop:disable Layout/LineLength
Minitest::Retry.use!(
  # These are the flapping tests that are able to pass by retrying them.
  methods_to_retry: %w[
    AdminUsersIndexTest#test_should_be_able_to_autocomplete_by_name
    BatchIngestTest#test_invalid_without_files
    DepositThesisTest#test_be_able_to_deposit_and_edit_a_thesis_successfully
    DraftControllerTest#test_should_not_be_able_to_update_a_draft_item_when_saving_upload_files_form_that_has_no_file_attachments
    DraftControllerTest#test_should_not_be_able_to_update_a_draft_thesis_when_saving_upload_files_form_that_has_no_file_attachments
    ItemListFilesTest#test_files_are_alphabetically_sorted_when_depositing_an_item
    ThesisListFilesTest#test_files_are_alphabetically_sorted_when_depositing_an_item
  ]
)
# rubocop:enable Layout/LineLength

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

# was removed from rdf-n3 in 3.1.2, restoring here
module RDF::Isomorphic
  alias == isomorphic_with?
end

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  load('db/seeds/rdf_annotations.rb')

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
    user = users(:user_system)
    api_key = '3eeb395e-63b7-11ea-bc55-0242ac130003'
    post auth_system_url, params: { email: user.email, api_key: api_key }
  end

  # Returns true if a test user is logged in.
  def logged_in?
    session[:user_id].present?
  end

  # Stub out `puts` and logger messages in our test suite as needed to avoid clutter.
  def disable_output(&block)
    $stdout.stub(:puts, nil, &block)
  end

  # turn on test mode for omniauth
  OmniAuth.config.test_mode = true

end

class ActionDispatch::IntegrationTest

  setup do
    host! URI(Jupiter::TEST_URL).host
  end

end
