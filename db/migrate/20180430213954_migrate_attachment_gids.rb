class MigrateAttachmentGids < ActiveRecord::Migration[5.2]
  def up
    ActiveStorage::Attachment.all.each do |attachment|
      next unless attachment.record_gid.present?
      record = GlobalID::Locator.locate(attachment.record_gid)
      next unless record.present?

      if record.is_a?(DraftItem)
        attachment.update_attribute(:record_id, record.id)
        attachment.update_attribute(:record_type, record.polymorphic_name)
      elsif [Community, Item, Thesis].include?(record.class)
        shim = JupiterCore::AttachmentShim.create(owner_global_id: attachment.record_gid, name: attachment.name)
        attachment.update_attribute(:record_id, shim.id)
        attachment.update_attribute(:record_type, shim.class.name)
        attachment.update_attribute(:name, :shimmed_file)
      else
        raise ArgumentError, "Couldn't migrate old GID for item attachment: #{attachment.id}"
      end
    end
    def down; end
  end
end
