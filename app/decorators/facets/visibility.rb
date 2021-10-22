class Facets::Visibility < Facets::URIValue

  def display_value
    translate_uri(:jupiter_core, :visibility, @value)
  end

end
