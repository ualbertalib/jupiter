class ReworkAttachments < ActiveRecord::Migration[5.2]
  def change
    add_column :active_storage_attachments, :record_id, :integer, limit: 8, null: true
    add_column :active_storage_attachments, :record_type, :string, null: true
    change_column :active_storage_attachments, :blob_id, :integer, limit: 8, null: false
  end
end
