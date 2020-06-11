module GraphCreation
  extend ActiveSupport::Concern

  def create_graph(rdfable_entity, prefixes, subject = nil)
    subject ||= self_subject
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
        next if value.blank?

        statement = RDF::Statement(
          subject: subject,
          predicate: RDF::Vocabulary::Term.new(rdf_annotation.predicate),
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

  def owner_email_statement
    RDF::Statement(
      subject: self_subject,
      predicate: RDF::Vocab::BIBO.owner,
      object: @entity.owner.email
    )
  end

  def rdf_type_statement(object)
    RDF::Statement(
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

  def derivate_list_values(
    rdfable_entity,
    subject,
    rdf_original_predicate,
    rdf_list_predicate = nil
  )
    rdf_list_predicate ||= rdf_original_predicate

    # Here we expect the value of @entity.send(column) to be a JSON array
    rdf_annotation = rdfable_entity.rdf_annotations.find_by(
      predicate: rdf_original_predicate.to_s
    )

    return nil unless rdf_annotation

    list = RDF::List(rdfable_entity.send(rdf_annotation.column))
    statement = RDF::Statement(
      subject: subject,
      predicate: rdf_list_predicate,
      object: list
    )

    [list, statement]
  end

  def delete_insert_list_values_statements(
    rdfable_entity,
    subject,
    rdf_original_predicate
  )

    {
      statements_to_insert: derivate_list_values(
        rdfable_entity,
        subject,
        rdf_original_predicate
      )
    }
  end
end
