class AddInitialReadOnlyModes < ActiveRecord::Migration[5.2]
  def change
    ReadOnlyMode.create(enabled: false)
  end
end
