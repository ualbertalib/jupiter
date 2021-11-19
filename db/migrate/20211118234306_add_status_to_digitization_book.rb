class AddStatusToDigitizationBook < ActiveRecord::Migration[6.1]
  def change
    add_column :digitization_books, :batch_ingest_status, :integer, default: 0, null: false
  end
end
