class Facets::Visibility < Facets::URIValue

  def display
    translate_uri(:visibility, @value)
  end

end
