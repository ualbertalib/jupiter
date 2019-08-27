class ChangeActivestorageRecordsToUuidPart2 < ActiveRecord::Migration[5.2]
  def change
    remove_column :active_storage_attachments, :record_id
    rename_column :active_storage_attachments, :upcoming_record_id, :record_id

    remove_column :draft_items, :id
    rename_column :draft_items, :upcoming_id, :id

    remove_column :draft_theses, :id
    rename_column :draft_theses, :upcoming_id, :id
  end
end
