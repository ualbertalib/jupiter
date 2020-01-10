class ChangeActivestorageRecordsToUuidPart2 < ActiveRecord::Migration[5.2]
  def change
    execute "UPDATE active_storage_attachments SET record_type = 'Community' where record_type = 'ArCommunity'"
    execute "UPDATE active_storage_attachments SET record_type = 'Item' where record_type = 'ArItem'"
    execute "UPDATE active_storage_attachments SET record_type = 'Thesis' where record_type = 'ArThesis'"
    execute "DELETE FROM active_storage_attachments WHERE record_type = 'JupiterCore::AttachmentShim'"
    remove_column :active_storage_attachments, :record_id
    rename_column :active_storage_attachments, :upcoming_record_id, :record_id

    remove_column :draft_items, :id
    rename_column :draft_items, :upcoming_id, :id
    execute 'ALTER TABLE draft_items ADD PRIMARY KEY (id);'

    remove_column :draft_theses, :id
    rename_column :draft_theses, :upcoming_id, :id
    execute 'ALTER TABLE draft_theses ADD PRIMARY KEY (id);'

    remove_column :draft_items_languages, :draft_item_id
    rename_column :draft_items_languages, :upcoming_draft_item_id, :draft_item_id
  end
end
