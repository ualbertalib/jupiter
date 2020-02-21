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
end
