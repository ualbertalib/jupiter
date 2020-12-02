class CreateBatchIngests < ActiveRecord::Migration[6.0]
  def change
    create_table :batch_ingests do |t|
      t.string :title, null: false
      t.integer :status, default: 0, null: false

      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :batch_ingests, :title, unique: true
  end
end
