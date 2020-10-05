class ChangeActivestorageRecordsToUuidPart2 < ActiveRecord::Migration[5.2]
  def change
    execute "UPDATE active_storage_attachments SET record_type = 'Community' where record_type = 'ArCommunity'"
    execute "UPDATE active_storage_attachments SET record_type = 'Item' where record_type = 'ArItem'"
    execute "UPDATE active_storage_attachments SET record_type = 'Thesis' where record_type = 'ArThesis'"
    execute "DELETE FROM active_storage_attachments WHERE record_type = 'JupiterCore::AttachmentShim'"
    remove_column :active_storage_attachments, :record_id
    rename_column :active_storage_attachments, :upcoming_record_id, :record_id

    remove_column :active_storage_attachments, :blob_id
    rename_column :active_storage_attachments, :upcoming_blob_id, :blob_id

    remove_column :draft_items, :id
    rename_column :draft_items, :upcoming_id, :id
    execute 'ALTER TABLE draft_items ADD PRIMARY KEY (id);'

    remove_column :draft_items, :thumbnail_id
    rename_column :draft_items, :upcoming_thumbnail_id, :thumbnail_id

    remove_column :draft_theses, :id
    rename_column :draft_theses, :upcoming_id, :id
    execute 'ALTER TABLE draft_theses ADD PRIMARY KEY (id);'

    remove_column :draft_theses, :thumbnail_id
    rename_column :draft_theses, :upcoming_thumbnail_id, :thumbnail_id

    remove_column :draft_items_languages, :draft_item_id
    rename_column :draft_items_languages, :upcoming_draft_item_id, :draft_item_id

    remove_column :active_storage_blobs, :id
    rename_column :active_storage_blobs, :upcoming_id, :id
    execute 'ALTER TABLE active_storage_blobs ADD PRIMARY KEY (id);'

    change_column_null :active_storage_attachments, :blob_id, false
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    add_index :active_storage_attachments, :blob_id
  end
end
