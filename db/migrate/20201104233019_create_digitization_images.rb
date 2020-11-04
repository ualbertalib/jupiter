class CreateDigitizationImages < ActiveRecord::Migration[6.0]
  def change
    create_table :digitization_images do |t|
      t.uuid :image_id
      t.string :peel_image_id

      t.timestamps
    end
  end
end
