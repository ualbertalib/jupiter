class Facets::License < Facets::URIValue

  def display_value
    translate_uri(:era, :license, @value)
  end

end
