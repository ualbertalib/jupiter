class Presenters::FacetValues::Languages < Presenters::FacetValues::URIValue

  def display
    translate_uri(:language, @value)
  end

end
