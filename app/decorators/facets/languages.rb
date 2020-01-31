class Facets::Languages < Facets::URIValue

  def display
    translate_uri(:language, @value)
  end

end
