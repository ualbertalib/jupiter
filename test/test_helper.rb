require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/hooks/test'
require 'active_fedora/cleaner'

class ActiveSupport::TestCase

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
  end

  # Add more helper methods to be used by all tests here...

end
