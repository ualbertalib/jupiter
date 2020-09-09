class CreateReadOnlyModes < ActiveRecord::Migration[6.0]
  def change
    create_table :read_only_modes do |t|
      t.boolean :enabled
    end
  end
end
