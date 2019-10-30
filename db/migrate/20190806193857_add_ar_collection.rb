class AddArCollection < ActiveRecord::Migration[5.2]
  def change
    create_table :ar_collections, id: :uuid,  default: 'uuid_generate_v4()' do |t|
      t.string :visibility
      t.references :owner, null: false, index: true, foreign_key: {to_table: :users, column: :id}
      t.datetime :record_created_at
      t.string :hydra_noid
      t.datetime :date_ingested
      t.string :title
      t.string :fedora3_uuid
      t.string :depositor
      t.uuid :community_id
      t.text :description
      t.json :creators, array: true
      t.boolean :restricted, default: false, null: false
      t.timestamps
    end
  end
end
