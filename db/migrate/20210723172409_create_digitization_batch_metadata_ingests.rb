class CreateDigitizationBatchMetadataIngests < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_batch_metadata_ingests, id: :uuid do |t|
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.string :error_message

      t.references :user, foreign_key: {to_table: :users, column: :id}

      t.timestamps
    end
  end
end
