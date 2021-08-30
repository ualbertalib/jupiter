class CreateDigitizationBatchArtifactSetupIngests < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_batch_artifact_setup_ingests, id: :uuid do |t|

      t.integer :status, default: 0, null: false
      t.string :error_message
      t.string :archival_information_package_path

      t.references :user, foreign_key: {to_table: :users, column: :id}

      t.timestamps
    end
  end
end
