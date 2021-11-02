class RenameDigitizationBatchIngest < ActiveRecord::Migration[6.1]
  def change
    remove_reference :digitization_books, :digitization_batch_metadata_ingest, index: {name: "index_digitization_books_on_batch_metadata_ingest_id"}, foreign_key: true, type: :uuid
    rename_table :digitization_batch_metadata_ingests, :digitization_batch_ingests
    add_reference :digitization_books, :digitization_batch_ingest, index: {name: "index_digitization_books_on_batch_ingest_id"}, foreign_key: true, type: :uuid

    change_table :digitization_batch_ingests, bulk: true do |t|
      t.string :type
    end
  end
end
