class CreateDigitizationMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_maps do |t|
      t.uuid :map_id
      t.string :peel_map_id

      t.timestamps
    end
  end
end
