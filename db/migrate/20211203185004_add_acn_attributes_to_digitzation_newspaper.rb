class AddAcnAttributesToDigitzationNewspaper < ActiveRecord::Migration[6.1]
  def change
    safety_assured { # this migration is a bunch of add_columns which are safe
      change_table :digitization_newspapers do |t|
        t.string :dates_issued, array:true
        t.text :alternative_titles, array: true
        t.string :resource_type, null: false
        t.string :genres, null: false, array: true
        t.string :languages, null: false, array: true
        t.string :places_of_publication, array:true
        t.string :extent
        t.text :notes, array: true
        t.string :geographic_subjects, array: true
        t.string :rights
        t.string :volume_label
        t.string :editions, array: true
      end
    }

    add_rdf_table_annotations for_table: :digitization_newspapers do |t|
      t.dates_issued has_predicate: ::RDF::Vocab::DC.issued
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.alternative_titles has_predicate: ::RDF::Vocab::DC.alternative
      t.resource_type has_predicate: ::RDF::Vocab::DC.type
      t.genres has_predicate: ::RDF::Vocab::EDM.hasType
      t.languages has_predicate: ::RDF::Vocab::DC.language
      t.places_of_publication has_predicate: ::RDF::Vocab::MARCRelators.pup
      t.extent has_predicate: ::TERMS[:rdau].extent
      t.notes has_predicate: ::RDF::Vocab::SKOS.note
      t.geographic_subjects has_predicate: ::RDF::Vocab::DC11.coverage
      t.rights has_predicate: ::RDF::Vocab::EDM.rights
      t.volume_label has_predicate: ::TERMS[:rdfs].ch_label
      t.editions has_predicate: ::RDF::Vocab::Bibframe.editionStatement
    end
  end
end
