class MigrateAttachmentGids < ActiveRecord::Migration[5.2]
  def up
    ActiveStorage::Attachment.all.each do |attachment|
      next unless attachment.record_gid.present?
      # record already processed, as when this migration may have previously errored out
      next if attachment.record_id.present? && attachment.record_type.present?

      begin
        record = GlobalID::Locator.locate(attachment.record_gid)
        next unless record.present?
      rescue JupiterCore::ObjectNotFound
        # purge the orphan attachment, as nothing actually owns it
        attachment.purge
        next
      end

      if record.is_a?(DraftItem)
        attachment.update_attribute(:record_id, record.id)
        attachment.update_attribute(:record_type, DraftItem.polymorphic_name)
      elsif [Community, Item, Thesis].include?(record.class)
        shim = JupiterCore::AttachmentShim.create(owner_global_id: attachment.record_gid, name: attachment.name)
        attachment.update_attribute(:record_id, shim.id)
        attachment.update_attribute(:record_type, shim.class.name)
        attachment.update_attribute(:name, :shimmed_file)
      else
        raise ArgumentError, "Couldn't migrate old GID for item attachment: #{attachment.id}"
      end
    end
  end
  def down; end

end
