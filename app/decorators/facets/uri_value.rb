class Facets::URIValue < Facets::DefaultFacetDecorator

  protected

  def translate_uri(namespace, vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol

    @view.humanize_uri(namespace, vocab, uri)
  end

end
