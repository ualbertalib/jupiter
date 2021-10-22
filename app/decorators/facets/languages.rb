class Facets::Languages < Facets::URIValue

  def display_value
    translate_uri(:era, :language, @value)
  end

end
