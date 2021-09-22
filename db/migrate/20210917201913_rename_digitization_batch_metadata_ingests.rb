class RenameDigitizationBatchMetadataIngests < ActiveRecord::Migration[6.0]
  def change
    rename_table :digitization_batch_metadata_ingests, :digitization_batch_ingests
  end
end
