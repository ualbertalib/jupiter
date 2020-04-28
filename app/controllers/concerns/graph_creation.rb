module GraphCreation
  extend ActiveSupport::Concern

  def create_graph(rdfable_entity, prefixes, subject = nil)
    subject = self_subject if subject.nil?
    graph = RDF::Graph.new
    annotations = get_prefixed_predicates(rdfable_entity, prefixes)

    annotations.each do |rdf_annotation|
      column = rdf_annotation.column

      # Treat all values as arrays so we can split individual values for each
      # predicate e.g. predicate <http://purl.org/dc/elements/1.1/subject> is
      # "Pictures", "Randomness", "Unicorn"
      # and not concatenated values like
      # "Pictures, Randomness, Unicorn"

      values = Array.wrap(rdfable_entity.send(column))

      values.each do |value|
        statement = prepare_statement(
          subject: subject,
          predicate: rdf_annotation.predicate,
          object: value
        )

        graph << statement unless statement.nil?
      end
    end

    graph
  end

  def get_prefixed_predicates(rdfable_entity, prefixes)
    result = RdfAnnotation.none
    ActsAsRdfable.add_annotation_bindings!(rdfable_entity)
    prefixes.each do |prefix|
      result = result.or rdfable_entity.rdf_annotations
                                       .where('predicate like :prefix',
                                              prefix: "#{prefix}%")
    end
    result
  end

  def prepare_statement(subject:, predicate:, object:)
    return if object.nil?

    object = [object] unless object.is_a?(Array)
    rdf_predicate = RDF::Vocabulary::Term.new(predicate)
    stringed_value = object.join(' , ')

    RDF::Statement(
      subject: subject,
      predicate: rdf_predicate,
      object: stringed_value
    )
  end

  def owner_email_statement
    prepare_statement(
      subject: self_subject,
      predicate: RDF::Vocab::BIBO.owner,
      object: @entity.owner.email
    )
  end

  def rdf_type_statement(object)
    prepare_statement(
      subject: self_subject,
      predicate: RDF.type,
      object: object
    )
  end

  # Return the url from the request to be used as the statement's subject for
  # each rdf annotation for the requested digital object
  def self_subject
    RDF::URI(request.url)
  end
end
