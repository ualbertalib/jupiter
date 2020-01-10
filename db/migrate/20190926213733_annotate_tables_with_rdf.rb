class AnnotateTablesWithRdf < ActiveRecord::Migration[5.2]
  def change
    add_rdf_table_annotations for_table: :items do |t|
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.fedora3_uuid has_predicate: ::TERMS[:ual].fedora3_uuid
      t.depositor has_predicate: ::TERMS[:ual].depositor
      t.alternative_title has_predicate: ::RDF::Vocab::DC.alternative
      t.doi has_predicate: ::TERMS[:prism].doi
      t.embargo_end_date has_predicate: ::RDF::Vocab::DC.available
      t.fedora3_handle has_predicate: ::TERMS[:ual].fedora3_handle
      t.ingest_batch has_predicate: ::TERMS[:ual].ingest_batch
      t.northern_north_america_filename has_predicate: ::TERMS[:ual].northern_north_america_filename
      t.northern_north_america_item_id has_predicate: ::TERMS[:ual].northern_north_america_item_id
      t.rights has_predicate: ::RDF::Vocab::DC11.rights
      t.sort_year has_predicate: ::TERMS[:ual].sort_year
      t.visibility_after_embargo has_predicate: ::TERMS[:acl].visibility_after_embargo
      t.embargo_history has_predicate: ::TERMS[:acl].embargo_history
      t.is_version_of has_predicate: ::RDF::Vocab::DC.isVersionOf
      t.member_of_paths has_predicate: ::TERMS[:ual].path
      t.subject has_predicate: ::RDF::Vocab::DC11.subject
      t.creators has_predicate: RDF::Vocab::BIBO.authorList
      t.contributors has_predicate: ::RDF::Vocab::DC11.contributor
      t.created has_predicate: ::RDF::Vocab::DC.created
      t.temporal_subjects has_predicate: ::RDF::Vocab::DC.temporal
      t.spatial_subjects has_predicate: ::RDF::Vocab::DC.spatial
      t.description has_predicate: ::RDF::Vocab::DC.description
      t.publisher has_predicate: ::RDF::Vocab::DC.publisher
      t.languages has_predicate: ::RDF::Vocab::DC.language
      t.license has_predicate: ::RDF::Vocab::DC.license
      t.item_type has_predicate: ::RDF::Vocab::DC.type
      t.source has_predicate: ::RDF::Vocab::DC.source
      t.related_link has_predicate: ::RDF::Vocab::DC.relation
      t.publication_status has_predicate: ::RDF::Vocab::BIBO.status
    end

    add_rdf_table_annotations for_table: :theses do |t|
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.fedora3_uuid has_predicate: ::TERMS[:ual].fedora3_uuid
      t.depositor has_predicate: ::TERMS[:ual].depositor
      t.alternative_title has_predicate: ::RDF::Vocab::DC.alternative
      t.doi has_predicate: ::TERMS[:prism].doi
      t.embargo_end_date has_predicate: ::RDF::Vocab::DC.available
      t.fedora3_handle has_predicate: ::TERMS[:ual].fedora3_handle
      t.ingest_batch has_predicate: ::TERMS[:ual].ingest_batch
      t.northern_north_america_filename has_predicate: ::TERMS[:ual].northern_north_america_filename
      t.northern_north_america_item_id has_predicate: ::TERMS[:ual].northern_north_america_item_id
      t.rights has_predicate: ::RDF::Vocab::DC11.rights
      t.sort_year has_predicate: ::TERMS[:ual].sort_year
      t.visibility_after_embargo has_predicate: ::TERMS[:acl].visibility_after_embargo
      t.embargo_history has_predicate: ::TERMS[:acl].embargo_history
      t.is_version_of has_predicate: ::RDF::Vocab::DC.isVersionOf
      t.member_of_paths has_predicate: ::TERMS[:ual].path
      t.subject has_predicate: ::RDF::Vocab::DC11.subject
      t.abstract has_predicate: ::RDF::Vocab::DC.abstract
      t.language has_predicate: ::RDF::Vocab::DC.language
      t.date_accepted has_predicate: ::RDF::Vocab::DC.dateAccepted
      t.date_submitted has_predicate: ::RDF::Vocab::DC.dateSubmitted
      t.degree has_predicate: ::RDF::Vocab::BIBO.degree
      t.institution has_predicate: TERMS[:swrc].institution
      t.dissertant has_predicate: TERMS[:ual].dissertant
      t.graduation_date has_predicate: TERMS[:ual].graduation_date
      t.thesis_level has_predicate: TERMS[:ual].thesis_level
      t.proquest has_predicate: TERMS[:ual].proquest
      t.unicorn has_predicate: TERMS[:ual].unicorn
      t.specialization has_predicate: TERMS[:ual].specialization
      t.departments has_predicate: TERMS[:ual].department_list
      t.supervisors has_predicate: TERMS[:ual].supervisor_list
      t.committee_members has_predicate: TERMS[:ual].committee_member
    end

    add_rdf_table_annotations for_table: :collections do |t|
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.fedora3_uuid has_predicate: ::TERMS[:ual].fedora3_uuid
      t.depositor has_predicate: ::TERMS[:ual].depositor
      t.community_id has_predicate: ::TERMS[:ual].path
      t.description has_predicate: ::RDF::Vocab::DC.description
      t.restricted has_predicate: ::TERMS[:ual].restricted_collection
      t.creators has_predicate: ::RDF::Vocab::DC.creator
    end

    add_rdf_table_annotations for_table: :communities do |t|
      t.title has_predicate: ::RDF::Vocab::DC.title
      t.fedora3_uuid has_predicate: ::TERMS[:ual].fedora3_uuid
      t.depositor has_predicate: ::TERMS[:ual].depositor
      t.description has_predicate: ::RDF::Vocab::DC.description
      t.creators has_predicate: ::RDF::Vocab::DC.creator
    end
  end
end
