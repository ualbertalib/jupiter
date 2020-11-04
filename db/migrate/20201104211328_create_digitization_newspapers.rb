class CreateDigitizationNewspapers < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_newspapers do |t|
      t.uuid :newspaper_id
      t.string :publication_code
      t.integer :year
      t.string :month
      t.string :day

      t.timestamps
    end
  end
end
