class ChangeActivestorageRecordsToUuidPart1 < ActiveRecord::Migration[5.2]
  def change
    add_column :active_storage_attachments, :upcoming_record_id, :uuid
    add_column :draft_items, :upcoming_id, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :draft_items, :upcoming_id, unique: true
    add_column :draft_theses, :upcoming_id, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :draft_theses, :upcoming_id, unique: true
    add_column :draft_items_languages, :upcoming_draft_item_id, :uuid
    add_index :draft_items_languages, :upcoming_draft_item_id
  end
end
