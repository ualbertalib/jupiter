class CreateDraftTheses < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_theses do |t|
      t.string :uuid

      t.integer :status, default: 0, null: false
      t.integer :wizard_step, default: 0, null: false

      t.references :user, null: false, index: true, foreign_key: true

      t.integer :thumbnail_id

      t.string :title
      t.string :alternate_title
      t.string :creator
      t.text :description

      t.string :degree
      t.string :degree_level
      t.string :institution
      t.string :specialization

      t.string :graduation_term
      t.integer :graduation_year

      t.references :language, index: true

      t.datetime :date_accepted
      t.datetime :date_submitted

      t.text :rights
      t.integer :visibility, default: 0, null: false
      t.datetime :embargo_end_date

      t.json :member_of_paths
      t.json :subjects, array: true
      t.json :supervisors, array: true
      t.json :departments, array: true
      t.json :committee_members, array: true

      t.timestamps
    end
  end
end
