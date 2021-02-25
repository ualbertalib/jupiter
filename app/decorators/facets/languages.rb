class Facets::Languages < Facets::URIValue

  def display
    translate_uri(:era, :language, @value)
  end

end
