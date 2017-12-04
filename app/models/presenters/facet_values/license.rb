class Presenters::FacetValues::License < Presenters::FacetValues::URIValue

  def display
    translate_uri(:license, @value)
  end

end
