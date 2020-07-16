class CreateArItem < ActiveRecord::Migration[5.2]
  def change
    create_table :ar_items, id: :uuid,  default: 'uuid_generate_v4()' do |t|
      t.string :visibility
      t.references :owner, null: false, index: true, foreign_key: {to_table: :users, column: :id}
      t.datetime :record_created_at
      t.string :hydra_noid
      t.datetime :date_ingested, null: false
      t.string :title, null: false
      t.string :fedora3_uuid
      t.string :depositor
      t.string :alternative_title
      t.string :doi
      t.datetime :embargo_end_date
      t.string :visibility_after_embargo
      t.string :fedora3_handle
      t.string :ingest_batch
      t.string :northern_north_america_filename
      t.string :northern_north_america_item_id
      t.text :rights
      t.integer :sort_year
      t.json :embargo_history, array: true
      t.json :is_version_of, array: true
      t.json :member_of_paths, null: false, array: true
      t.json :subject, array: true
      t.json :creators, array: true
      t.json :contributors, array: true
      t.string :created
      t.json :temporal_subjects, array: true
      t.json :spatial_subjects, array: true
      t.text :description
      t.string :publisher
      t.json :languages, array: true
      t.text :license
      t.string :item_type
      t.string :source
      t.string :related_link
      t.json :publication_status, array: true
      t.references :logo, foreign_key: {to_table: :active_storage_attachments, column: :id, on_delete: :nullify}
      t.string :aasm_state
      t.timestamps
    end
  end
end
