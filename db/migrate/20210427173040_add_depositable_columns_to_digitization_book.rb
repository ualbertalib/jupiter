class AddDepositableColumnsToDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    change_table :digitization_books do |t|
      t.datetime :date_ingested, null: false
      t.datetime :record_created_at
      t.string :visibility
      t.references :owner, null: false, index: true, foreign_key: {to_table: :users, column: :id}
    end

    add_rdf_table_annotations for_table: :digitization_books do |t|
      t.date_ingested has_predicate: RDF::Vocab::EBUCore.dateIngested
      t.record_created_at has_predicate: ::TERMS[:ual].record_created_in_jupiter
    end
  end
end
