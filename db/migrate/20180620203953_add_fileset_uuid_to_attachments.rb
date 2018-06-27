class AddFilesetUuidToAttachments < ActiveRecord::Migration[5.2]
  def change
    add_column :active_storage_attachments, :fileset_uuid, :uuid, null: true
  end
end
