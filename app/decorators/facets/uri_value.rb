class Facets::URIValue < Facets::DefaultFacetDecorator

  protected

  def translate_uri(namespace, vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol
    raise ArgumentError, "Namespace not found: #{namespace}" unless CONTROLLED_VOCABULARIES.key?(namespace)
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES[namespace].key?(vocab)

    @view.humanize_uri(namespace, vocab, uri)
  end

end
