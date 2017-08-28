# Note that this file can go away in Rails 5.2 because 'class_attribute' has
# support for a 'default' value.
# The default value is set in the ActiveStorage gem in
# lib/active_storage/verified_key_with_expiration.rb

require 'active_storage'
require 'active_storage/verified_key_with_expiration.rb'
require 'active_storage/attached'

ActiveStorage::VerifiedKeyWithExpiration.verifier =
  Rails.application.message_verifier('ActiveStorage')

# Monkey patch ActiveStorage to replace existing attachments
class ActiveStorage::Attached::One < ActiveStorage::Attached

  def attachment
    # Return most recent
    @attachment ||=
      ActiveStorage::Attachment.where(record_gid: record.to_gid.to_s, name: name)
                               .order(:created_at).last
  end

  def attach(attachable)
    # Removing any previous attachments when updating
    old_attachments =
      ActiveStorage::Attachment.where(record_gid: record.to_gid.to_s, name: name).to_a
    @attachment =
      ActiveStorage::Attachment.create!(record_gid: record.to_gid.to_s,
                                        name: name, blob: create_blob_from(attachable))
    old_attachments.each(&:purge_later)
  end

end
