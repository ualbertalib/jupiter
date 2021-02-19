class CreateVocabularies < ActiveRecord::Migration[6.0]
  def change
    create_table :vocabularies do |t|
      t.string :namespace
      t.string :vocab
      t.string :uri
      t.string :code

      t.timestamps
    end
  end
end
