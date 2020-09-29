class AnnotateTablesWithDateIngestedAndCreatedPredicates < ActiveRecord::Migration[6.0]
  def change
    add_rdf_table_annotations for_table: :items do |t|
      t.date_ingested has_predicate: RDF::Vocab::EBUCore.dateIngested
      t.record_created_at has_predicate: ::TERMS[:ual].record_created_in_jupiter
    end

    add_rdf_table_annotations for_table: :theses do |t|
      t.date_ingested has_predicate: RDF::Vocab::EBUCore.dateIngested
      t.record_created_at has_predicate: ::TERMS[:ual].record_created_in_jupiter
    end

    add_rdf_table_annotations for_table: :collections do |t|
      t.date_ingested has_predicate: RDF::Vocab::EBUCore.dateIngested
      t.record_created_at has_predicate: ::TERMS[:ual].record_created_in_jupiter
    end

    add_rdf_table_annotations for_table: :communities do |t|
      t.date_ingested has_predicate: RDF::Vocab::EBUCore.dateIngested
      t.record_created_at has_predicate: ::TERMS[:ual].record_created_in_jupiter
    end
  end
end
