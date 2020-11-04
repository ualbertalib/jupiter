class CreateDigitizationBooks < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_books do |t|
      t.uuid :book_id
      t.integer :peel_id
      t.integer :run
      t.integer :part_number

      t.timestamps
    end
  end
end
