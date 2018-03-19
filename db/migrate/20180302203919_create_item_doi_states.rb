class CreateItemDoiStates < ActiveRecord::Migration[5.1]
  def change
    create_table :item_doi_states do |t|
      t.uuid :item_id
      t.string  :aasm_state

      t.timestamps
    end
  end
end
