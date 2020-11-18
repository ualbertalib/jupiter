class CreateDigitizationNewspapers < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_newspapers, id: :uuid do |t|
      t.string :publication_code, :year, :month, :day, null: true

      t.timestamps
    end
    add_index :digitization_newspapers, [:publication_code, :year, :month, :day], unique: true, name: :unique_peel_newspaper
  end
end
