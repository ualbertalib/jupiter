class Digitization::BatchMetadataIngestionJob < ApplicationJob

  PEEL_ID_REGEX = /P0*(\d+).(\d*)/.freeze

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_ingest = arguments.first
    batch_ingest.update(error_message: exception.message, status: :failed)
    raise exception
  end

  def perform(batch_ingest)
    batch_ingest.processing!

    ActiveRecord::Base.transaction do
      batch_ingest.csvfile.open do |file|
        graph = metadata_graph(file.path)
        create_items_from_graph(graph, batch_ingest)
      end
    end

    batch_ingest.completed!
  end

  private

  def metadata_graph(csv_path)
    graph = RDF::Graph.new
    CSV.foreach(csv_path, headers: true) do |row|
      subject = RDF::URI.new(row['Entity'], validate: true)
      predicate = RDF::URI.new(row['Property'], validate: true)
      object = begin
        RDF::URI.new(row['Value'], validate: true)
      rescue StandardError
        RDF::Literal.new(row['Value'])
      end
      graph << [subject, predicate, object]
    end

    graph
  end

  URI_CODE_TO_TRANSFORM_METHOD = {
    'http://id.loc.gov/vocabulary/identifiers/local': :parse_identifier
  }.freeze

  def create_items_from_graph(graph, batch_ingest)
    query_for_local_identifiers = RDF::Query.new do
      pattern [:collection, RDF::URI.new('http://rdaregistry.info/Elements/u/P60249'), :item_identifier]
    end

    graph.query(query_for_local_identifiers) do |statement|
      book = batch_ingest.books.new(owner_id: batch_ingest.user_id)

      query_for_this_items_attributes = RDF::Query.new do
        pattern [statement.item_identifier, :predicate, :term]
        pattern [:term, RDF::Vocab::SKOS.prefLabel, :label], optional: true
      end
      graph.query(query_for_this_items_attributes) do |attributes|
        delegate_transform(book, attributes)

        assign_attribute(book, book.attribute_for_rdf_annotation(attributes.predicate.to_s)&.first&.column,
                         attributes.term.to_s)
      end

      book.save!
    end
  end

  def delegate_transform(book, attributes)
    return if attributes.predicate.to_s.blank?

    return if URI_CODE_TO_TRANSFORM_METHOD[attributes.predicate.to_s.to_sym].blank?

    send(URI_CODE_TO_TRANSFORM_METHOD[attributes.predicate.to_s.to_sym], book, attributes.term.to_s)
  end

  def parse_identifier(book, term)
    matches = term.match PEEL_ID_REGEX
    book.peel_id = matches[1]
    book.part_number = matches[2]
  end

  def assign_attribute(book, attribute, term)
    return if attribute.blank?

    if book.send(attribute.to_s).is_a? Array
      book.send(attribute.to_s).push(term)
    else
      book.send("#{attribute}=", term)

      # Don't know in advance if this will be an array or a literal
      # if the first attempt made it an array (from nil) it's an array
      book.send(attribute.to_s).push(term) if book.send(attribute.to_s).is_a? Array
    end
  end

end
