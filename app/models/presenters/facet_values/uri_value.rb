class Presenters::FacetValues::URIValue < Presenters::FacetValues::DefaultPresenter

  protected

  def translate_uri(vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES.key?(vocab)
    CONTROLLED_VOCABULARIES[vocab].each do |entry|
      if entry[:uri] == uri
        return I18n.t("controlled_vocabularies.#{vocab}.#{entry[:code]}")
      end
    end
    raise ArgumentError, "URI: #{uri} not found in vocabulary: #{vocab}"
  end

end
