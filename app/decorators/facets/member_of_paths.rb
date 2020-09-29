class Facets::MemberOfPaths < Facets::DefaultFacetDecorator

  def display
    # This would be the seam where we may want to introduce a more efficient cache for mapping
    # community_id/collection_id paths to titles, as this is going to get hit a lot on facet results
    # If names were unique, we wouldn't have to do this translation, but c'est la vie
    community_id, collection_id = @value.split('/')
    community_title = Community.find(community_id).title
    collection_title = if collection_id
                         "/#{Collection.find(collection_id).title}"
                       else
                         ''
                       end
    community_title + collection_title
  end

end
