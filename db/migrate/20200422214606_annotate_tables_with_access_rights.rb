class AnnotateTablesWithAccessRights < ActiveRecord::Migration[6.0]
  def change
    add_rdf_table_annotations for_table: :items do |t|
      t.visibility has_predicate: ::RDF::Vocab::DC.accessRights
    end

    add_rdf_table_annotations for_table: :theses do |t|
      t.visibility has_predicate: ::RDF::Vocab::DC.accessRights
    end

    add_rdf_table_annotations for_table: :collections do |t|
      t.visibility has_predicate: ::RDF::Vocab::DC.accessRights
    end

    add_rdf_table_annotations for_table: :communities do |t|
      t.visibility has_predicate: ::RDF::Vocab::DC.accessRights
    end
  end
end
