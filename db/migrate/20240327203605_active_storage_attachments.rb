class ActiveStorageAttachments < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_index :active_storage_attachments, :record_id, algorithm: :concurrently, if_not_exists: true
  end
end
