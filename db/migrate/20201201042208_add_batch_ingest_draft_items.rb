class AddBatchIngestDraftItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :draft_items, :batch_ingest, foreign_key: true
  end
end
