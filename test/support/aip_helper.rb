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

  # TODO: We will very likely stop using the create_entity method once settle on a consistent way of defining data for
  # our tests. Initially the entities were fetched from fixtures instead of being instantiated, however multiple tests
  # for Item entity started flipping with this approach, likely having to do with the order the tests were run. The
  # errors included:
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

  def load_rendered_graph(entity, postfix)
    # n3_template repalces the 2 fileset uuids because they will change everytime the test is run and the files are added
    fileset_0_uuid = entity.files[0].fileset_uuid
    fileset_1_uuid = entity.files[1].fileset_uuid

    n3_template = ERB.new(file_fixture("n3/#{entity.id}-#{postfix}.n3").read)
    generate_graph_from_n3(n3_template.result(binding))
  end

  def seed_active_storage_blobs_rdf_annotations
    active_storage_blob_table_name = ActiveStorage::Blob.table_name.freeze
    RdfAnnotation.create_or_find_by(table: active_storage_blob_table_name, column: 'byte_size',
                                    predicate: RDF::Vocab::PREMIS.hasSize)
    RdfAnnotation.create_or_find_by(table: active_storage_blob_table_name, column: 'checksum',
                                    predicate: RDF::Vocab::PREMIS.hasMessageDigest)
    RdfAnnotation.create_or_find_by(table: active_storage_blob_table_name, column: 'content_type',
                                    predicate: RDF::Vocab::EBUCore.hasMimeType)
    RdfAnnotation.create_or_find_by(table: active_storage_blob_table_name, column: 'filename',
                                    predicate: RDF::Vocab::EBUCore.resourceFilename)
  end

  def seed_collections_rdf_annotations
    collection_table_name = Collection.table_name.freeze
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'community_id', predicate: TERMS[:ual].path)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'creators', predicate: RDF::Vocab::DC.creator)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'date_ingested',
                                    predicate: RDF::Vocab::EBUCore.dateIngested)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'depositor', predicate: TERMS[:ual].depositor)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'description',
                                    predicate: RDF::Vocab::DC.description)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'fedora3_uuid',
                                    predicate: TERMS[:ual].fedora3_uuid)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'hydra_noid',
                                    predicate: TERMS[:ual].hydra_noid)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'record_created_at',
                                    predicate: TERMS[:ual].record_created_in_jupiter)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'restricted',
                                    predicate: TERMS[:ual].restricted_collection)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'title', predicate: RDF::Vocab::DC.title)
    RdfAnnotation.create_or_find_by(table: collection_table_name, column: 'visibility',
                                    predicate: RDF::Vocab::DC.accessRights)
  end

  def seed_communities_rdf_annotations
    community_table_name = Community.table_name.freeze
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'creators', predicate: RDF::Vocab::DC.creator)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'date_ingested',
                                    predicate: RDF::Vocab::EBUCore.dateIngested)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'depositor', predicate: TERMS[:ual].depositor)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'description',
                                    predicate: RDF::Vocab::DC.description)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'fedora3_uuid',
                                    predicate: TERMS[:ual].fedora3_uuid)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'hydra_noid',
                                    predicate: TERMS[:ual].hydra_noid)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'record_created_at',
                                    predicate: TERMS[:ual].record_created_in_jupiter)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'title', predicate: RDF::Vocab::DC.title)
    RdfAnnotation.create_or_find_by(table: community_table_name, column: 'visibility',
                                    predicate: RDF::Vocab::DC.accessRights)
  end

  def seed_item_rdf_annotations
    item_table_name = Item.table_name.freeze
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'alternative_title',
                                    predicate: RDF::Vocab::DC.alternative)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'contributors',
                                    predicate: RDF::Vocab::DC11.contributor)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'created', predicate: RDF::Vocab::DC.created)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'creators', predicate: RDF::Vocab::DC11.creator)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'date_ingested',
                                    predicate: RDF::Vocab::EBUCore.dateIngested)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'depositor', predicate: TERMS[:ual].depositor)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'description',
                                    predicate: RDF::Vocab::DC.description)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'doi', predicate: TERMS[:prism].doi)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'embargo_end_date',
                                    predicate: RDF::Vocab::DC.available)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'embargo_history',
                                    predicate: TERMS[:acl].embargo_history)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'fedora3_handle',
                                    predicate: TERMS[:ual].fedora3_handle)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'fedora3_uuid', predicate: TERMS[:ual].fedora3_uuid)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'hydra_noid', predicate: TERMS[:ual].hydra_noid)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'ingest_batch', predicate: TERMS[:ual].ingest_batch)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'is_version_of',
                                    predicate: RDF::Vocab::DC.isVersionOf)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'item_type', predicate: RDF::Vocab::DC.type)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'languages', predicate: RDF::Vocab::DC.language)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'license', predicate: RDF::Vocab::DC.license)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'member_of_paths', predicate: TERMS[:ual].path)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'northern_north_america_filename',
                                    predicate: TERMS[:ual].northern_north_america_filename)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'northern_north_america_item_id',
                                    predicate: TERMS[:ual].northern_north_america_item_id)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'publication_status',
                                    predicate: RDF::Vocab::BIBO.status)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'publisher', predicate: RDF::Vocab::DC.publisher)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'record_created_at',
                                    predicate: TERMS[:ual].record_created_in_jupiter)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'related_link', predicate: RDF::Vocab::DC.relation)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'rights', predicate: RDF::Vocab::DC11.rights)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'sort_year', predicate: TERMS[:ual].sort_year)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'source', predicate: RDF::Vocab::DC.source)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'spatial_subjects',
                                    predicate: RDF::Vocab::DC.spatial)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'subject', predicate: RDF::Vocab::DC11.subject)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'temporal_subjects',
                                    predicate: RDF::Vocab::DC.temporal)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'title', predicate: RDF::Vocab::DC.title)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'visibility_after_embargo',
                                    predicate: TERMS[:acl].visibility_after_embargo)
    RdfAnnotation.create_or_find_by(table: item_table_name, column: 'visibility',
                                    predicate: RDF::Vocab::DC.accessRights)
  end

  def seed_theses_rdf_annotations
    thesis_table_name = Thesis.table_name.freeze
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'abstract', predicate: RDF::Vocab::DC.abstract)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'alternative_title',
                                    predicate: RDF::Vocab::DC.alternative)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'committee_members',
                                    predicate: TERMS[:ual].committee_member)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'date_accepted',
                                    predicate: RDF::Vocab::DC.dateAccepted)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'date_ingested',
                                    predicate: RDF::Vocab::EBUCore.dateIngested)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'date_submitted',
                                    predicate: RDF::Vocab::DC.dateSubmitted)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'degree', predicate: RDF::Vocab::BIBO.degree)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'departments',
                                    predicate: TERMS[:ual].department_list)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'depositor', predicate: TERMS[:ual].depositor)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'dissertant', predicate: TERMS[:ual].dissertant)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'doi', predicate: TERMS[:prism].doi)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'embargo_end_date',
                                    predicate: RDF::Vocab::DC.available)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'embargo_history',
                                    predicate: TERMS[:acl].embargo_history)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'fedora3_handle',
                                    predicate: TERMS[:ual].fedora3_handle)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'fedora3_uuid',
                                    predicate: TERMS[:ual].fedora3_uuid)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'graduation_date',
                                    predicate: TERMS[:ual].graduation_date)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'hydra_noid', predicate: TERMS[:ual].hydra_noid)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'ingest_batch',
                                    predicate: TERMS[:ual].ingest_batch)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'institution',
                                    predicate: TERMS[:swrc].institution)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'is_version_of',
                                    predicate: RDF::Vocab::DC.isVersionOf)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'language', predicate: RDF::Vocab::DC.language)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'member_of_paths', predicate: TERMS[:ual].path)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'northern_north_america_filename',
                                    predicate: TERMS[:ual].northern_north_america_filename)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'northern_north_america_item_id',
                                    predicate: TERMS[:ual].northern_north_america_item_id)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'proquest', predicate: TERMS[:ual].proquest)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'record_created_at',
                                    predicate: TERMS[:ual].record_created_in_jupiter)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'rights', predicate: RDF::Vocab::DC11.rights)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'sort_year', predicate: TERMS[:ual].sort_year)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'specialization',
                                    predicate: TERMS[:ual].specialization)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'subject', predicate: RDF::Vocab::DC11.subject)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'supervisors',
                                    predicate: TERMS[:ual].supervisor_list)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'thesis_level',
                                    predicate: TERMS[:ual].thesis_level)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'title', predicate: RDF::Vocab::DC.title)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'unicorn', predicate: TERMS[:ual].unicorn)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'visibility_after_embargo',
                                    predicate: TERMS[:acl].visibility_after_embargo)
    RdfAnnotation.create_or_find_by(table: thesis_table_name, column: 'visibility',
                                    predicate: RDF::Vocab::DC.accessRights)
  end

  def seed_all_rdf_annotations
    seed_active_storage_blobs_rdf_annotations
    seed_collections_rdf_annotations
    seed_communities_rdf_annotations
    seed_item_rdf_annotations
    seed_theses_rdf_annotations
  end
end
