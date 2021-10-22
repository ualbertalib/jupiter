class Facets::CommunityId < Facets::DefaultFacetDecorator

  def display_value
    Community.find(@value).title
  end

end
