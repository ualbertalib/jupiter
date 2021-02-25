class Facets::License < Facets::URIValue

  def display
    translate_uri(:era, :license, @value)
  end

end
