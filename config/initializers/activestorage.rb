# Note that this file can go away in Rails 5.2 because 'class_attribute' has
# support for a 'default' value.
# The default value is set in the ActiveStorage gem in
# lib/active_storage/verified_key_with_expiration.rb

require 'active_storage'
require 'active_storage/verified_key_with_expiration.rb'
ActiveStorage::VerifiedKeyWithExpiration.verifier =
  Rails.application.message_verifier('ActiveStorage')
