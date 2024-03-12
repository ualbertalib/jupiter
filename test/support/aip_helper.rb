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
    xsd = Nokogiri::XML::Schema(File.open(file_fixture('file-order.xsd')), Nokogiri::XML::ParseOptions.new.nononet)
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
    community ||= communities(:community_fancy)
    collection ||= collections(:collection_fancy)

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

  def load_radioactive_n3_graph(entity, postfix)
    # We fetch the values for community and collections UUIDs because they are not hardcoded into the entity fixture,
    # but instead they are identified from fixtures community_fancy and collection_fancy
    community_uuid, collection_uuid = entity.member_of_paths.first.split('/')

    # n3_template in load_n3_graph method repalces the 2 fileset uuids because they will change everytime the test is
    # run and the files are added
    variables = {
      fileset_0_uuid: entity.files[0].fileset_uuid,
      fileset_1_uuid: entity.files[1].fileset_uuid,
      url: Rails.application.secrets.test_url,
      community_uuid:,
      collection_uuid:
    }

    load_n3_graph(file_fixture("n3/#{entity.class.table_name}/#{entity.id}-#{postfix}.n3"), variables)
  end

  def load_n3_graph(path, variables = nil)
    b = binding
    variables&.each do |key, value|
      b.local_variable_set(key, value)
    end

    n3_template = ERB.new(path.read)
    generate_graph_from_n3(n3_template.result(b))
  end
end
