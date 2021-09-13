class AddDigitizationBatchIngestItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :digitization_books, :digitization_batch_metadata_ingest, index: {name: "index_digitization_books_on_batch_metadata_ingest_id"}, foreign_key: true, type: :uuid
  end
end
