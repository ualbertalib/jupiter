class CreateDigitizationImages < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_images, id: :uuid do |t|
      t.string :peel_image_id, null: true

      t.timestamps
    end
    add_index :digitization_images, :peel_image_id, unique: true, name: :unique_peel_image
  end
end
