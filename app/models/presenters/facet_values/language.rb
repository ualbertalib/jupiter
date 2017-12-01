class Presenters::FacetValues::Language < Presenters::FacetValues::DefaultPresenter

  def display
    CONTROLLED_VOCABULARIES[:language].each do |lang|
      if lang[:uri] == @value
        return I18n.t("controlled_vocabularies.language.#{lang[:code]}")
      end
    end
    raise ApplicationError("Language not found for #{language_uri}")
  end

end
