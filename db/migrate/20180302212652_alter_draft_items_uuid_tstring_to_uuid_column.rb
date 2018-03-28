class AlterDraftItemsUuidTstringToUuidColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :draft_items, :uuid, 'uuid USING CAST(uuid AS uuid)'
  end
end
