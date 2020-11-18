class CreateDigitizationMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_maps, id: :uuid do |t|
      t.string :peel_map_id, null: true

      t.timestamps
    end
    add_index :digitization_maps, :peel_map_id, unique: true, name: :unique_peel_map
  end
end
