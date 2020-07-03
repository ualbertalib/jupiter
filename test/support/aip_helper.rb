module AipHelper
  extend ActiveSupport::Concern

  protected

  def generate_graph_from_n3(data)
    graph = RDF::Graph.new
    RDF::Reader.for(:n3).new(data) do |reader|
      reader.each_statement do |statement|
        graph << statement
      end
    end

    graph
  end

  def check_file_order_xml(data)
    xsd = Nokogiri::XML::Schema(File.open(file_fixture('file-order.xsd')))
    doc = Nokogiri::XML(data)
    xsd.valid?(doc)
  end

  def get_n3_graph(url)
    get url
    generate_graph_from_n3(response.body)
  end

  def file_paths_json_schema
    {
      type: 'object',
      required: [:files],
      properties: {
        files: {
          type: 'array',
          items: {
            type: 'object',
            required: [
              :file_name,
              :file_path,
              :file_uuid,
              :file_checksum
            ],
            properties: {
              file_name: {
                type: 'string'
              },
              file_path: {
                type: 'string'
              },
              file_uuid: {
                type: 'string'
              },
              file_checksum: {
                type: 'string'
              }
            }
          }
        }
      }
    }
  end

  # TODO: We will very likely stop using the create_entity method once settle on
  # a consistent way of defining data for our tests. Initially the entities were
  # fetched from fixtures instead of being instantiated, however multiple tests
  # for Item entity started flipping with this approach, likely having to do
  # with the order the tests were run. The errors included:
  # - No items on the database
  # - Items not being found on database by id
  # - Items defined to have files did not contain them

  def create_entity(
    entity_class: Item,
    parameters: {},
    files: [],
    community: nil,
    collection: nil
  )
    community ||= communities(:fancy_community)
    collection ||= collections(:fancy_collection)

    entity = entity_class.new(parameters).tap do |current_entity|
      current_entity.add_to_path(community.id, collection.id)
      current_entity.save!
    end

    Sidekiq::Testing.inline! do
      files.map do |file|
        File.open(file, 'r') do |file_handle|
          entity.add_and_ingest_files([file_handle])
        end
      end
    end

    entity
  end

  def seed_active_storage_blobs_rdf_annotations
    active_storage_blob_table_name = ActiveStorage::Blob.table_name.freeze
    RdfAnnotation.create(table: active_storage_blob_table_name, column: 'byte_size', predicate: 'http://www.loc.gov/premis/rdf/v1#hasSize')
    RdfAnnotation.create(table: active_storage_blob_table_name, column: 'checksum', predicate: 'http://www.loc.gov/premis/rdf/v1#hasMessageDigest')
    RdfAnnotation.create(table: active_storage_blob_table_name, column: 'content_type', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#hasMimeType')
    RdfAnnotation.create(table: active_storage_blob_table_name, column: 'filename', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#resourceFilename')
  end

  def seed_collections_rdf_annotations
    collection_table_name = Collection.table_name.freeze
    RdfAnnotation.create(table: collection_table_name, column: 'community_id', predicate: 'http://terms.library.ualberta.ca/path')
    RdfAnnotation.create(table: collection_table_name, column: 'creators', predicate: 'http://purl.org/dc/terms/creator')
    RdfAnnotation.create(table: collection_table_name, column: 'date_ingested', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested')
    RdfAnnotation.create(table: collection_table_name, column: 'depositor', predicate: 'http://terms.library.ualberta.ca/depositor')
    RdfAnnotation.create(table: collection_table_name, column: 'description', predicate: 'http://purl.org/dc/terms/description')
    RdfAnnotation.create(table: collection_table_name, column: 'fedora3_uuid', predicate: 'http://terms.library.ualberta.ca/fedora3UUID')
    RdfAnnotation.create(table: collection_table_name, column: 'hydra_noid', predicate: 'http://terms.library.ualberta.ca/hydraNoid')
    RdfAnnotation.create(table: collection_table_name, column: 'record_created_at', predicate: 'http://terms.library.ualberta.ca/recordCreatedInJupiter')
    RdfAnnotation.create(table: collection_table_name, column: 'restricted', predicate: 'http://terms.library.ualberta.ca/restrictedCollection')
    RdfAnnotation.create(table: collection_table_name, column: 'title', predicate: 'http://purl.org/dc/terms/title')
    RdfAnnotation.create(table: collection_table_name, column: 'visibility', predicate: 'http://purl.org/dc/terms/accessRights')
  end

  def seed_communities_rdf_annotations
    community_table_name = Community.table_name.freeze
    RdfAnnotation.create(table: community_table_name, column: 'creators', predicate: 'http://purl.org/dc/terms/creator')
    RdfAnnotation.create(table: community_table_name, column: 'date_ingested', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested')
    RdfAnnotation.create(table: community_table_name, column: 'depositor', predicate: 'http://terms.library.ualberta.ca/depositor')
    RdfAnnotation.create(table: community_table_name, column: 'description', predicate: 'http://purl.org/dc/terms/description')
    RdfAnnotation.create(table: community_table_name, column: 'fedora3_uuid', predicate: 'http://terms.library.ualberta.ca/fedora3UUID')
    RdfAnnotation.create(table: community_table_name, column: 'hydra_noid', predicate: 'http://terms.library.ualberta.ca/hydraNoid')
    RdfAnnotation.create(table: community_table_name, column: 'record_created_at', predicate: 'http://terms.library.ualberta.ca/recordCreatedInJupiter')
    RdfAnnotation.create(table: community_table_name, column: 'title', predicate: 'http://purl.org/dc/terms/title')
    RdfAnnotation.create(table: community_table_name, column: 'visibility', predicate: 'http://purl.org/dc/terms/accessRights')
  end

  def seed_item_rdf_annotations
    item_table_name = Item.table_name.freeze
    RdfAnnotation.create(table: item_table_name, column: 'alternative_title', predicate: 'http://purl.org/dc/terms/alternative')
    RdfAnnotation.create(table: item_table_name, column: 'contributors', predicate: 'http://purl.org/dc/elements/1.1/contributor')
    RdfAnnotation.create(table: item_table_name, column: 'created', predicate: 'http://purl.org/dc/terms/created')
    RdfAnnotation.create(table: item_table_name, column: 'creators', predicate: 'http://purl.org/dc/elements/1.1/creator')
    RdfAnnotation.create(table: item_table_name, column: 'date_ingested', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested')
    RdfAnnotation.create(table: item_table_name, column: 'depositor', predicate: 'http://terms.library.ualberta.ca/depositor')
    RdfAnnotation.create(table: item_table_name, column: 'description', predicate: 'http://purl.org/dc/terms/description')
    RdfAnnotation.create(table: item_table_name, column: 'doi', predicate: 'http://prismstandard.org/namespaces/basic/3.0/doi')
    RdfAnnotation.create(table: item_table_name, column: 'embargo_end_date', predicate: 'http://purl.org/dc/terms/available')
    RdfAnnotation.create(table: item_table_name, column: 'embargo_history', predicate: 'http://projecthydra.org/ns/auth/acl#embargoHistory')
    RdfAnnotation.create(table: item_table_name, column: 'fedora3_handle', predicate: 'http://terms.library.ualberta.ca/fedora3Handle')
    RdfAnnotation.create(table: item_table_name, column: 'fedora3_uuid', predicate: 'http://terms.library.ualberta.ca/fedora3UUID')
    RdfAnnotation.create(table: item_table_name, column: 'hydra_noid', predicate: 'http://terms.library.ualberta.ca/hydraNoid')
    RdfAnnotation.create(table: item_table_name, column: 'ingest_batch', predicate: 'http://terms.library.ualberta.ca/ingestBatch')
    RdfAnnotation.create(table: item_table_name, column: 'is_version_of', predicate: 'http://purl.org/dc/terms/isVersionOf')
    RdfAnnotation.create(table: item_table_name, column: 'item_type', predicate: 'http://purl.org/dc/terms/type')
    RdfAnnotation.create(table: item_table_name, column: 'languages', predicate: 'http://purl.org/dc/terms/language')
    RdfAnnotation.create(table: item_table_name, column: 'license', predicate: 'http://purl.org/dc/terms/license')
    RdfAnnotation.create(table: item_table_name, column: 'member_of_paths', predicate: 'http://terms.library.ualberta.ca/path')
    RdfAnnotation.create(table: item_table_name, column: 'northern_north_america_filename', predicate: 'http://terms.library.ualberta.ca/nnaFile')
    RdfAnnotation.create(table: item_table_name, column: 'northern_north_america_item_id', predicate: 'http://terms.library.ualberta.ca/nnaItem')
    RdfAnnotation.create(table: item_table_name, column: 'publication_status', predicate: 'http://purl.org/ontology/bibo/status')
    RdfAnnotation.create(table: item_table_name, column: 'publisher', predicate: 'http://purl.org/dc/terms/publisher')
    RdfAnnotation.create(table: item_table_name, column: 'record_created_at', predicate: 'http://terms.library.ualberta.ca/recordCreatedInJupiter')
    RdfAnnotation.create(table: item_table_name, column: 'related_link', predicate: 'http://purl.org/dc/terms/relation')
    RdfAnnotation.create(table: item_table_name, column: 'rights', predicate: 'http://purl.org/dc/elements/1.1/rights')
    RdfAnnotation.create(table: item_table_name, column: 'sort_year', predicate: 'http://terms.library.ualberta.ca/sortYear')
    RdfAnnotation.create(table: item_table_name, column: 'source', predicate: 'http://purl.org/dc/terms/source')
    RdfAnnotation.create(table: item_table_name, column: 'spatial_subjects', predicate: 'http://purl.org/dc/terms/spatial')
    RdfAnnotation.create(table: item_table_name, column: 'subject', predicate: 'http://purl.org/dc/elements/1.1/subject')
    RdfAnnotation.create(table: item_table_name, column: 'temporal_subjects', predicate: 'http://purl.org/dc/terms/temporal')
    RdfAnnotation.create(table: item_table_name, column: 'title', predicate: 'http://purl.org/dc/terms/title')
    RdfAnnotation.create(table: item_table_name, column: 'visibility_after_embargo', predicate: 'http://projecthydra.org/ns/auth/acl#visibilityAfterEmbargo')
    RdfAnnotation.create(table: item_table_name, column: 'visibility', predicate: 'http://purl.org/dc/terms/accessRights')
  end

  def seed_theses_rdf_annotations
    thesis_table_name = Thesis.table_name.freeze
    RdfAnnotation.create(table: thesis_table_name, column: 'abstract', predicate: 'http://purl.org/dc/terms/abstract')
    RdfAnnotation.create(table: thesis_table_name, column: 'alternative_title', predicate: 'http://purl.org/dc/terms/alternative')
    RdfAnnotation.create(table: thesis_table_name, column: 'committee_members', predicate: 'http://terms.library.ualberta.ca/commiteeMember')
    RdfAnnotation.create(table: thesis_table_name, column: 'date_accepted', predicate: 'http://purl.org/dc/terms/dateAccepted')
    RdfAnnotation.create(table: thesis_table_name, column: 'date_ingested', predicate: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested')
    RdfAnnotation.create(table: thesis_table_name, column: 'date_submitted', predicate: 'http://purl.org/dc/terms/dateSubmitted')
    RdfAnnotation.create(table: thesis_table_name, column: 'degree', predicate: 'http://purl.org/ontology/bibo/degree')
    RdfAnnotation.create(table: thesis_table_name, column: 'departments', predicate: 'http://terms.library.ualberta.ca/departmentList')
    RdfAnnotation.create(table: thesis_table_name, column: 'depositor', predicate: 'http://terms.library.ualberta.ca/depositor')
    RdfAnnotation.create(table: thesis_table_name, column: 'dissertant', predicate: 'http://terms.library.ualberta.ca/dissertant')
    RdfAnnotation.create(table: thesis_table_name, column: 'doi', predicate: 'http://prismstandard.org/namespaces/basic/3.0/doi')
    RdfAnnotation.create(table: thesis_table_name, column: 'embargo_end_date', predicate: 'http://purl.org/dc/terms/available')
    RdfAnnotation.create(table: thesis_table_name, column: 'embargo_history', predicate: 'http://projecthydra.org/ns/auth/acl#embargoHistory')
    RdfAnnotation.create(table: thesis_table_name, column: 'fedora3_handle', predicate: 'http://terms.library.ualberta.ca/fedora3Handle')
    RdfAnnotation.create(table: thesis_table_name, column: 'fedora3_uuid', predicate: 'http://terms.library.ualberta.ca/fedora3UUID')
    RdfAnnotation.create(table: thesis_table_name, column: 'graduation_date', predicate: 'http://terms.library.ualberta.ca/graduationDate')
    RdfAnnotation.create(table: thesis_table_name, column: 'hydra_noid', predicate: 'http://terms.library.ualberta.ca/hydraNoid')
    RdfAnnotation.create(table: thesis_table_name, column: 'ingest_batch', predicate: 'http://terms.library.ualberta.ca/ingestBatch')
    RdfAnnotation.create(table: thesis_table_name, column: 'institution', predicate: 'http://ontoware.org/swrc/ontology#institution')
    RdfAnnotation.create(table: thesis_table_name, column: 'is_version_of', predicate: 'http://purl.org/dc/terms/isVersionOf')
    RdfAnnotation.create(table: thesis_table_name, column: 'language', predicate: 'http://purl.org/dc/terms/language')
    RdfAnnotation.create(table: thesis_table_name, column: 'member_of_paths', predicate: 'http://terms.library.ualberta.ca/path')
    RdfAnnotation.create(table: thesis_table_name, column: 'northern_north_america_filename', predicate: 'http://terms.library.ualberta.ca/nnaFile')
    RdfAnnotation.create(table: thesis_table_name, column: 'northern_north_america_item_id', predicate: 'http://terms.library.ualberta.ca/nnaItem')
    RdfAnnotation.create(table: thesis_table_name, column: 'proquest', predicate: 'http://terms.library.ualberta.ca/proquest')
    RdfAnnotation.create(table: thesis_table_name, column: 'record_created_at', predicate: 'http://terms.library.ualberta.ca/recordCreatedInJupiter')
    RdfAnnotation.create(table: thesis_table_name, column: 'rights', predicate: 'http://purl.org/dc/elements/1.1/rights')
    RdfAnnotation.create(table: thesis_table_name, column: 'sort_year', predicate: 'http://terms.library.ualberta.ca/sortYear')
    RdfAnnotation.create(table: thesis_table_name, column: 'specialization', predicate: 'http://terms.library.ualberta.ca/specialization')
    RdfAnnotation.create(table: thesis_table_name, column: 'subject', predicate: 'http://purl.org/dc/elements/1.1/subject')
    RdfAnnotation.create(table: thesis_table_name, column: 'supervisors', predicate: 'http://terms.library.ualberta.ca/supervisorList')
    RdfAnnotation.create(table: thesis_table_name, column: 'thesis_level', predicate: 'http://terms.library.ualberta.ca/thesisLevel')
    RdfAnnotation.create(table: thesis_table_name, column: 'title', predicate: 'http://purl.org/dc/terms/title')
    RdfAnnotation.create(table: thesis_table_name, column: 'unicorn', predicate: 'http://terms.library.ualberta.ca/unicorn')
    RdfAnnotation.create(table: thesis_table_name, column: 'visibility_after_embargo', predicate: 'http://projecthydra.org/ns/auth/acl#visibilityAfterEmbargo')
    RdfAnnotation.create(table: thesis_table_name, column: 'visibility', predicate: 'http://purl.org/dc/terms/accessRights')
  end

  def ingest_files_for_entity(entity)
    file_paths = [
      'test/fixtures/files/image-sample.jpeg',
      'test/fixtures/files/image-sample2.jpeg'
    ]

    file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        entity.add_and_ingest_files([file])
      end
    end
  end

  def seed_all_rdf_annotations
    seed_active_storage_blobs_rdf_annotations
    seed_collections_rdf_annotations
    seed_communities_rdf_annotations
    seed_item_rdf_annotations
    seed_theses_rdf_annotations
  end
end
