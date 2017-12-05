class CreateDraftItemTables < ActiveRecord::Migration[5.1]

  def change

    create_table :types do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items do |t|
      t.string :uuid
      t.boolean :complete, null: false, default: false

      t.string :title, null: false
      t.string :alternate_title
      t.date :date_created, null: false
      t.text :description, null: false
      t.string :source
      t.string :related_item

      t.string :license, null: false
      t.text :license_text_area

      t.string :visibility, null: false
      t.datetime :embargo_date

      t.belongs_to :type, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :languages do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :languages do |t|
      t.index :draft_item_id
      t.index :language_id

      t.timestamps
    end

    create_table :creators do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :creators do |t|
      t.index :draft_item_id
      t.index :creator_id

      t.timestamps
    end

    create_table :subjects do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :subjects do |t|
      t.index :draft_item_id
      t.index :subject_id

      t.timestamps
    end

    create_table :community_and_collections do |t|
      t.string   :community_id, null: false
      t.string   :collection_id, null: false

      t.timestamps
    end

    create_join_table :draft_items, :community_and_collections do |t|
      t.index :draft_item_id
      # Original index name was too long for MYSQL, shortened it by abbreviating community_and_collections
      t.index :community_and_collection_id, name: 'index_c_and_cs_draft_items_on_community_and_collection_id'

      t.timestamps
    end

    create_table :contributors do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :contributors do |t|
      t.index :draft_item_id
      t.index :contributor_id

      t.timestamps
    end

    create_table :places do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :places do |t|
      t.index :draft_item_id
      t.index :place_id

      t.timestamps
    end

    create_table :time_periods do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :time_periods do |t|
      t.index :draft_item_id
      t.index :time_period_id

      t.timestamps
    end

    create_table :citations do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_join_table :draft_items, :citations do |t|
      t.index :draft_item_id
      t.index :citation_id

      t.timestamps
    end
  end

end
