class GenerateReportsJob < ApplicationJob

  queue_as :default

  def perform(*args)
    # Do something later
    @root_directory = './era_audit/'
    @time_of_start = Time.now.utc.strftime('%Y%m%d%H%M%S')

    generate_reports
  end

  private

  # Helper methods to get URLs.

  def get_entity_url(entity)
    # URL example: https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
    Rails.application.routes.url_helpers.item_url(entity)
  end

  def get_community_url(community)
    # URL example: https://era.library.ualberta.ca/communities/d1640714-da95-4963-9242-68065fece5f4
    Rails.application.routes.url_helpers.community_url(community)
  end

  def get_collection_url(community, collection)
    # URL example: https://era.library.ualberta.ca/communities/34de6895-e488-440b-b05c-75efe26c4971/collections/67e0ecb3-05b7-4c9a-bf82-31611e2dc0ce
    Rails.application.routes.url_helpers.community_collection_url(community, collection)
  end

  def generate_reports
    report_metadata_only_records
    report_file_types
    report_records_with_compressed_files
    report_multifile_records
  end

  # Report 1: Metadata only records

  def report_metadata_only_records
    [Item, Thesis].each do |klass|
      entity_type = klass.name.underscore
      entity_attributes = klass.first.attributes.keys
      entity_headers = entity_attributes.map do |key|
        klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
      end
      file_name = "#{@root_directory}/#{entity_type}_with_metadata_only_#{@time_of_start}.csv"
      CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
        klass.find_each do |entity|
          csv << (entity.values_at(entity_attributes) + [get_entity_url(entity)]) if entity.files.count == 0
        end
      end
    end
  end

  # Report 2: List of file types

  def report_file_types
    entity_file_types = {}

    file_name = "#{@root_directory}/entity_file_types_#{@time_of_start}.csv"

    [Item, Thesis].each do |klass|
      klass.find_each do |entity|
        entity.files.each do |file|
          content_type = file.content_type
          entity_file_types[content_type] = 0 unless entity_file_types.include?(content_type)
          entity_file_types[content_type] += 1
        end
      end
    end

    CSV.open(file_name, 'wb', write_headers: true, headers: ['File types', 'Count']) do |csv|
      entity_file_types.each do |content_type, count|
        csv << [content_type, count]
      end
    end
  end

  # Report 3: List of records containing compressed files
  def report_records_with_compressed_files
    compressed_file_types = [
      'application/zip',
      'application/x-7z-compressed',
      'application/gzip',
      'application/x-xz',
      'application/x-rar-compressed;version=5',
      'application/x-tar',
      'application/x-rar'
    ]

    [Item, Thesis].each do |klass|
      entity_type = klass.name.underscore
      entity_attributes = klass.first.attributes.keys
      entity_headers = entity_attributes.map do |key|
        klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
      end

      file_name = "#{@root_directory}/#{entity_type}_with_compressed_file_#{@time_of_start}.csv"

      CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL', 'Files metadata']) do |csv|
        klass.find_each do |entity|
          file_metadata = []

          entity.files.each do |file|
            content_type = file.content_type
            file_metadata << file.blob.to_json if compressed_file_types.include?(content_type)
          end

          unless file_metadata.empty?
            csv << (entity.values_at(entity_attributes) + [get_entity_url(entity),
                                                           file_metadata])
          end
        end
      end
    end
  end

  # Report 4: List of all multi file records
  def report_multifile_records
    [Item, Thesis].each do |klass|
      entity_type = klass.name.underscore
      entity_attributes = klass.first.attributes.keys
      entity_headers = entity_attributes.map do |key|
        klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
      end

      file_name = "#{@root_directory}/#{entity_type}_with_multiple_files_#{@time_of_start}.csv"
      CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL', 'Files metadata']) do |csv|
        klass.includes(files_attachments: :blob).find_each do |entity|
          if entity.files.count > 1
            files_metadata = []
            entity.files.each do |file|
              files_metadata << file.blob.to_json
            end
            csv << entity.values_at(entity_attributes) + [get_entity_url(entity), files_metadata]
          end
        end
      end
    end
  end

end
