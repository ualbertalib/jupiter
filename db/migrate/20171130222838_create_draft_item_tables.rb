class CreateDraftItemTables < ActiveRecord::Migration[5.1]

  def change
    create_table :types do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items do |t|
      t.string :uuid

      t.integer :status, default: 0, null: false
      t.integer :wizard_step, default: 0, null: false

      t.string :title
      t.string :alternate_title
      t.date :date_created
      t.text :description
      t.string :source
      t.string :related_item

      t.integer :license, default: 0, null: false
      t.text :license_text_area

      t.integer :visibility, default: 0, null: false
      t.datetime :embargo_date

      t.references :type, index: true
      t.references :user, null: false, index: true, foreign_key: true

      t.json :creators, :json, array: true
      t.json :subjects, :json, array: true
      t.json :community_and_collections, :json
      t.json :contributors, :json, array: true
      t.json :places, :json, array: true
      t.json :time_periods, :json, array: true
      t.json :citations, :json, array: true

      t.timestamps
    end

    create_table :languages do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_languages, id: false do |t|
      t.references :draft_item, index: true
      t.references :language, index: true

      t.timestamps
    end
  end

end
