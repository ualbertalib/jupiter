class CreateDigitizationBooks < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_books, id: :uuid do |t|
      t.integer :peel_id, :run, :part_number, null: true 

      t.timestamps
    end
    add_index :digitization_books, [:peel_id, :run, :part_number], unique: true, name: :unique_peel_book
  end
end
