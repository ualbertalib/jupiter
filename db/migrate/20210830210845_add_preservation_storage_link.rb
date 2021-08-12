class AddPreservationStorageLink < ActiveRecord::Migration[6.0]
  def change
    change_table :digitization_books do |t|
      t.string :swift_noid
      t.string :swift_container
      t.string :preservation_storage
    end

    add_rdf_table_annotations for_table: :digitization_books do |t|
      t.swift_noid has_predicate: ::TERMS[:premisrelationshipsubtype].supersedes
      t.preservation_storage has_predicate: RDF::Vocab::MARCRelators.rps
    end
  end
end
