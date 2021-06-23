class CreateBatchIngestFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :batch_ingest_files do |t|
      t.string :google_file_name, null: false
      t.string :google_file_id, null: false

      t.references :batch_ingest, foreign_key: true

      t.timestamps
    end
  end
end
