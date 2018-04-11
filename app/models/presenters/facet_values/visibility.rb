class Presenters::FacetValues::Visibility < Presenters::FacetValues::URIValue

  def display
    translate_uri(:visibility, @value)
  end

end
