class Facets::CommunityId < Facets::DefaultFacetDecorator

  def display
    Community.find(@value).title
  end

end
