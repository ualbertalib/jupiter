class AddArCommunity < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
    create_table :ar_communities, id: :uuid,  default: 'uuid_generate_v4()' do |t|
      t.string :visibility
      t.references :owner, null: false, index: true, foreign_key: {to_table: :users, column: :id}
      t.datetime :record_created_at
      t.string :hydra_noid
      t.datetime :date_ingested
      t.string :title
      t.string :fedora3_uuid
      t.string :depositor
      t.text :description
      t.json :creators, array: true
      t.references :logo, foreign_key: {to_table: :active_storage_attachments, column: :id}
      t.timestamps
    end
  end
end
