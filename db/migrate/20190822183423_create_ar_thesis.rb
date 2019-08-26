class CreateArThesis < ActiveRecord::Migration[5.2]
  def change
    create_table :ar_theses, id: :uuid,  default: 'uuid_generate_v4()' do |t|
      t.string :visibility
      t.references :owner, null: false, index: true, foreign_key: {to_table: :users, column: :id}
      t.datetime :record_created_at
      t.string :hydra_noid
      t.datetime :date_ingested
      t.string :title
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
      t.string :is_version_of

      t.json :member_of_paths, array: true
      t.json :subject, array: true

      t.text :abstract
      t.string :language
      t.datetime :date_accepted
      t.datetime :date_submitted
      t.string :degree
      t.string :institution
      t.string :dissertant
      t.string :graduation_date
      t.string :thesis_level
      t.string :proquest
      t.string :unicorn
      t.string :specialization
      t.json :departments, array: true
      t.json :supervisors, array: true
      t.json :committee_members, array: true
      t.references :logo, foreign_key: {to_table: :active_storage_attachments, column: :id}

      t.timestamps
    end
  end
end
