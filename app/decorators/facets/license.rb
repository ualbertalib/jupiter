class Facets::License < Facets::DefaultFacetDecorator

  def display
    translate_uri(:license, @value)
  end

end
