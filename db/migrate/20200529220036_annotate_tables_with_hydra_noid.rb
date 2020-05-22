class AnnotateTablesWithHydraNoid < ActiveRecord::Migration[6.0]
  def change
    add_rdf_table_annotations for_table: :items do |t|
      t.hydra_noid has_predicate: ::TERMS[:ual].hydra_noid
    end

    add_rdf_table_annotations for_table: :theses do |t|
      t.hydra_noid has_predicate: ::TERMS[:ual].hydra_noid
    end

    add_rdf_table_annotations for_table: :collections do |t|
      t.hydra_noid has_predicate: ::TERMS[:ual].hydra_noid
    end

    add_rdf_table_annotations for_table: :communities do |t|
      t.hydra_noid has_predicate: ::TERMS[:ual].hydra_noid
    end
  end
end
