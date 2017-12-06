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

      t.string :license
      t.text :license_text_area

      t.string :visibility
      t.datetime :embargo_date

      t.references :type, index: true
      t.references :user, null: false, index: true, foreign_key: true

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

    create_table :creators do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_creators, id: false do |t|
      t.references :draft_item, index: true
      t.references :creator, index: true

      t.timestamps
    end

    create_table :subjects do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_subjects, id: false do |t|
      t.references :draft_item, index: true
      t.references :subject, index: true

      t.timestamps
    end

    create_table :community_and_collections do |t|
      t.string   :community_id, null: false
      t.string   :collection_id, null: false

      t.timestamps
    end

    create_table :draft_items_community_and_collections, id: false do |t|
      t.references :draft_item, index: true
      # Original index name was too long for MYSQL, shortened it by abbreviating community_and_collections
      t.references :community_and_collection, index: { name: 'index_comm_and_colls_draft_items_on_comm_and_coll_id' }

      t.timestamps
    end

    create_table :contributors do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_contributors, id: false do |t|
      t.references :draft_item, index: true
      t.references :contributor, index: true

      t.timestamps
    end

    create_table :places do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_places, id: false do |t|
      t.references :draft_item, index: true
      t.references :place, index: true

      t.timestamps
    end

    create_table :time_periods do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_time_periods, id: false do |t|
      t.references :draft_item, index: true
      t.references :time_period, index: true

      t.timestamps
    end

    create_table :citations do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :draft_items_citations, id: false do |t|
      t.references :draft_item, index: true
      t.references :citation, index: true

      t.timestamps
    end
  end

end
