class CreateReadOnlyModes < ActiveRecord::Migration[6.0]
  def change
    create_table :read_only_modes do |t|
      t.boolean :enabled, null: false, default: false
    end
  end
end
