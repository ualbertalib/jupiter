class DropGidFromAttachments < ActiveRecord::Migration[5.2]
  def up
    remove_column :active_storage_attachments, :record_gid
  end
end
