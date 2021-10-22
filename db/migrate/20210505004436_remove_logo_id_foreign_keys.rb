class RemoveLogoIdForeignKeys < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key "items", "active_storage_attachments", column: "logo_id"
    remove_foreign_key "theses", "active_storage_attachments", column: "logo_id"
  end
end
