class Presenters::FacetValues::URIValue < Presenters::FacetValues::DefaultPresenter

  protected

  def translate_uri(vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES.key?(vocab)
    @view.humanize_uri(vocab, uri)
  end

end
