class CreateAttachmentShims < ActiveRecord::Migration[5.2]
  def change
    create_table :attachment_shims do |t|
      t.string :owner_global_id, null: false
      t.string :name, null: false
      t.timestamps
    end
  end
end
