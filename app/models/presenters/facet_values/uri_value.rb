class Presenters::FacetValues::URIValue < Presenters::FacetValues::DefaultPresenter

  protected

  def translate_uri(vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES.key?(vocab)
    CONTROLLED_VOCABULARIES[vocab].uri_to_text(uri)
  end

end
