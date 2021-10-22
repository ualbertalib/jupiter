class AddFolkFestAttributesToDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    change_table :digitization_books do |t|
      t.string :date_issued, array:true
      t.string :temporal_subject, array:true
      t.string :title, null: false
      t.text :alt_title, array: true
      t.string :resource_type, null: false
      t.string :genre, null: false, array: true
      t.string :language, null: false, array: true
      t.string :publisher, array: true
      t.string :place_of_publication, array:true
      t.string :extent
      t.text :note, array: true
      t.string :geographic_subject, array: true
      t.string :rights
      t.string :topical_subject, array: true
    end

    add_rdf_table_annotations for_table: :digitization_books do |t|
      t.date_issued has_predicate: ::RDF::Vocab::DC.issued
      t.temporal_subject has_predicate: ::RDF::Vocab::SCHEMA.temporalCoverage
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.alt_title has_predicate: ::RDF::Vocab::DC.alternative
      t.resource_type has_predicate: ::RDF::Vocab::DC.type
      t.genre has_predicate: ::RDF::Vocab::EDM.hasType
      t.language has_predicate: ::RDF::Vocab::DC.language
      t.publisher has_predicate: ::RDF::Vocab::MARCRelators.pbl
      t.place_of_publication has_predicate: ::RDF::Vocab::MARCRelators.pup
      t.extent has_predicate: ::TERMS[:rdau].extent
      t.note has_predicate: ::RDF::Vocab::SKOS.note
      t.geographic_subject has_predicate: ::RDF::Vocab::DC11.coverage
      t.rights has_predicate: ::RDF::Vocab::DC11.rights
      t.topical_subject has_predicate: ::RDF::Vocab::DC11.subject
    end
  end
end
