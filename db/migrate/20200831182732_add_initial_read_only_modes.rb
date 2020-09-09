class AddInitialReadOnlyModes < ActiveRecord::Migration[6.0]
  def change
    ReadOnlyMode.create(enabled: false)
  end
end
