class Presenters::FacetValues::URIValue < Presenters::FacetValues::DefaultPresenter

  protected

  def translate_uri(vocab, uri)
    raise ArgumentError unless vocab.is_a? Symbol
    CONTROLLED_VOCABULARIES[vocab].each do |entry|
      if entry[:uri] == uri
        return I18n.t("controlled_vocabularies.#{vocab}.#{entry[:code]}")
      end
    end
    raise ArgumentError, "Vocabulary not found: #{vocab}"
  end

end
