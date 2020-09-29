class RdfGraphCreationService

  attr_reader :graph

  def initialize(rdfable_entity, prefixes, subject)
    @rdfable_entity = rdfable_entity
    @annotations = get_prefixed_predicates(prefixes)
    @subject = subject
    create_graph
  end

  def copy_predicate_to_sorted_rdf_list(subject, rdf_original_predicate, rdf_list_predicate)
    @graph.insert(*derivate_list_values(subject, rdf_original_predicate, rdf_list_predicate))
  end

  def replace_predicate_with_sorted_rdf_list(subject, rdf_original_predicate)
    return unless @graph.has_predicate?(rdf_original_predicate)

    @graph.delete_insert(
      @graph.query(predicate: rdf_original_predicate),
      derivate_list_values(subject, rdf_original_predicate)
    )
  end

  private

  def create_graph
    @graph = RDF::Graph.new
    @annotations.each do |rdf_annotation|
      column = rdf_annotation.column

      # Treat all values as arrays so we can split individual values for each
      # predicate e.g. predicate <http://purl.org/dc/elements/1.1/subject> is
      # "Pictures", "Randomness", "Unicorn"
      # and not concatenated values like
      # "Pictures, Randomness, Unicorn"

      values = Array.wrap(@rdfable_entity.send(column))

      values.each do |value|
        next if value.blank?

        @graph << RDF::Statement(
          subject: @subject,
          predicate: RDF::Vocabulary::Term.new(rdf_annotation.predicate),
          object: value
        )
      end
    end
  end

  def get_prefixed_predicates(prefixes)
    result = RdfAnnotation.none
    ActsAsRdfable.add_annotation_bindings!(@rdfable_entity)

    prefixes.each do |prefix|
      result = result.or(@rdfable_entity.rdf_annotations.where('predicate like :prefix', prefix: "#{prefix}%"))
    end

    result
  end

  def derivate_list_values(subject, rdf_original_predicate, rdf_list_predicate = nil)
    rdf_list_predicate ||= rdf_original_predicate

    rdf_annotation = @rdfable_entity.rdf_annotations.find_by(predicate: rdf_original_predicate.to_s)

    return nil unless rdf_annotation

    # Here we expect the value of @rdfable_entity.send(column) to be a JSON array
    list = RDF::List(@rdfable_entity.send(rdf_annotation.column))
    statement = RDF::Statement(subject: subject, predicate: rdf_list_predicate, object: list)

    [list, statement]
  end

end
