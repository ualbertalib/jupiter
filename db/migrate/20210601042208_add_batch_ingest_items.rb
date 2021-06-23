class AddBatchIngestItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :items, :batch_ingest, foreign_key: true
  end
end
