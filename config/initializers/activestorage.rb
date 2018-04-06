require 'active_storage'
require 'active_storage/verified_key_with_expiration.rb'
require 'active_storage/attached'

# Monkey patch ActiveStorage to replace existing attachments
# https://github.com/rails/activestorage/blob/v0.1/lib/active_storage/attached/one.rb
class ActiveStorage::Attached::One < ActiveStorage::Attached

  def attachment
    # Return most recent
    @attachment ||= ActiveStorage::Attachment
                    .where(record_gid: record.id ? record.to_gid.to_s : nil, name: name)
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

# Turn these methods into pass-throughs to disable signing blob URLs
class ActiveStorage::VerifiedKeyWithExpiration

  class << self

    # rubocop:disable Lint/UnusedMethodArgument
    def encode(key, expires_in: nil)
      key
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def decode(encoded_key)
      encoded_key
    end

  end

end
