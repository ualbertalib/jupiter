class Presenters::FacetValues::Language < Presenters::FacetValues::URIValue

  def display
    translate_uri(:language, @value)
  end

end
