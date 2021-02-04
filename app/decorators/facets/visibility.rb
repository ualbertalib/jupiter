class Facets::Visibility < Facets::URIValue

  def display_value
    translate_uri(:era, :visibility, @value)
  end

end
