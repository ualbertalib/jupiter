class ChangeActivestorageRecordsToUuidPart2 < ActiveRecord::Migration[5.2]
  def change
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
