class Facets::License < Facets::URIValue

  def display
    translate_uri(:license, @value)
  end

end
