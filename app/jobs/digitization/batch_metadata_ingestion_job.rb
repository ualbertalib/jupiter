class Digitization::BatchMetadataIngestionJob < ApplicationJob

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_metadata_ingest = arguments.first
    batch_metadata_ingest.update(error_message: exception.message, status: :failed)
    raise exception
  end

  def perform(batch_metadata_ingest)
    batch_metadata_ingest.processing!

    ActiveRecord::Base.transaction do
      batch_metadata_ingest.csvfile.open do |file|
        graph = metadata_graph(file.path)
        create_items_from_graph(graph, batch_metadata_ingest)
      end
    end

    batch_metadata_ingest.completed!
  end

  private

  # Here we read the graph from the csv file
  # the graph is made up of subject, predicate, object triples where subjects and objects are nodes in the graph and predicates are edges
  # See here for more about [RDF](https://www.w3.org/TR/rdf11-concepts/)
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

  # For more information about the query patterns used see here https://rubydoc.info/github/ruby-rdf/rdf/RDF/Query
  def create_items_from_graph(graph, batch_metadata_ingest)
    # First we need to locate all the discrete items we will be ingesting
    query_for_local_identifiers = RDF::Query.new do
      pattern [:collection, ::TERMS[:rdau].part, :item_identifier]
    end

    graph.query(query_for_local_identifiers) do |statement|
      # Each of the discrete items will become its own object
      book = batch_metadata_ingest.books.new(owner_id: batch_metadata_ingest.user_id)

      # Now we want know all about each item
      query_for_this_items_attributes = RDF::Query.new do
        pattern [statement.item_identifier, :predicate, :term]
        pattern [:term, RDF::Vocab::SKOS.prefLabel, :label], optional: true
      end
      graph.query(query_for_this_items_attributes) do |attributes|
        if RDF::Vocab::Identifiers.local == attributes.predicate
          # There isn't a single local identifier attribute in our model so we will need to parse this value
          parse_identifier(book, attributes.term.to_s)
        else
          assign_attribute(book, book.attribute_for_rdf_annotation(attributes.predicate.to_s)&.first&.column,
                           attributes.term.to_s)
        end
      end
      book.save!
    end
  end

  # use: parse_identifier(book, 'P010572.1')
  # result: book.peel_id = 10572, book.part_number = 1
  def parse_identifier(book, term)
    matches = term.match Digitization::PEEL_ID_REGEX
    book.peel_id = matches[1]
    book.part_number = matches[2]
  end

  # Use a bit of metaprogramming here to simplify the assignments of attributes
  # use: assign_attribute(book, 'dates_issued', '1991')
  # result: book.dates_issued = ['1991']
  def assign_attribute(book, attribute, term)
    return if attribute.blank?

    if book.class.columns_hash[attribute.to_s].array?
      book.send("#{attribute}=", []) if book.send(attribute.to_s).blank?
      book.send(attribute.to_s).push(term)
    else
      book.send("#{attribute}=", term)
    end
  end

end
