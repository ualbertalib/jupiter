class CreateVocabularies < ActiveRecord::Migration[6.0]
  def change
    create_table :vocabularies do |t|
      t.string :namespace
      t.string :vocab
      t.string :uri
      t.string :code

      t.timestamps

      t.index [:uri, :vocab, :namespace], unique: true
      t.index [:code, :vocab, :namespace], unique: true
    end
  end
end
