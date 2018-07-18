class AddLogoIdToAttachmentShims < ActiveRecord::Migration[5.2]
  def change
    add_column :attachment_shims, :logo_id, :integer, limit: 8, null: true, default: nil
  end
end
