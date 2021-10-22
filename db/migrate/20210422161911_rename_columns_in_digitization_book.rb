class RenameColumnsInDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    change_table :digitization_books do |t|
      t.rename :alt_title, :alternative_titles
      t.rename :language, :languages
      t.rename :date_issued, :dates_issued
      t.rename :temporal_subject, :temporal_subjects
      t.rename :genre, :genres
      t.rename :publisher, :publishers
      t.rename :place_of_publication, :places_of_publication
      t.rename :note, :notes
      t.rename :geographic_subject, :geographic_subjects
      t.rename :topical_subject, :topical_subjects
    end

    remove_rdf_table_annotations :digitization_books

    add_rdf_table_annotations for_table: :digitization_books do |t|
      t.dates_issued has_predicate: ::RDF::Vocab::DC.issued
      t.temporal_subjects has_predicate: ::RDF::Vocab::SCHEMA.temporalCoverage
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.alternative_title has_predicate: ::RDF::Vocab::DC.alternative
      t.resource_type has_predicate: ::RDF::Vocab::DC.type
      t.genres has_predicate: ::RDF::Vocab::EDM.hasType
      t.languages has_predicate: ::RDF::Vocab::DC.language
      t.publishers has_predicate: ::RDF::Vocab::MARCRelators.pbl
      t.places_of_publication has_predicate: ::RDF::Vocab::MARCRelators.pup
      t.extent has_predicate: ::TERMS[:rdau].extent
      t.notes has_predicate: ::RDF::Vocab::SKOS.note
      t.geographic_subjects has_predicate: ::RDF::Vocab::DC11.coverage
      t.rights has_predicate: ::RDF::Vocab::DC11.rights
      t.topical_subjects has_predicate: ::RDF::Vocab::DC11.subject
    end
  end
end
