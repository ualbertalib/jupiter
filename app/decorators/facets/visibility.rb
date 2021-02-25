class Facets::Visibility < Facets::URIValue

  def display
    translate_uri(:era, :visibility, @value)
  end

end
