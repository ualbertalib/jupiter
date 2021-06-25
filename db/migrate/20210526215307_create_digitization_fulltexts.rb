class CreateDigitizationFulltexts < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_fulltexts, id: :uuid do |t|
      t.references :digitization_book, type: :uuid, null: false, index: true, foreign_key: true
      t.text :text, null: false

      t.timestamps
    end
  end
end
