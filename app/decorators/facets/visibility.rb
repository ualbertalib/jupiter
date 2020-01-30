class Facets::Visibility < Facets::DefaultFacetDecorator

  def display
    translate_uri(:visibility, @value)
  end

end
