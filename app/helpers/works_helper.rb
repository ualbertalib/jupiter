module WorksHelper
  def to_named_path(path)
    return unless path
    community_id, collection_id = path.split('/')
    @community = Community.find(community_id)
    @collection = Collection.find(collection_id)
    community_link = link_to(@community.title, community_path(@community))
    collection_link = link_to(@collection.title, community_collection_path(@community, @collection))
    "#{community_link}/#{collection_link}".html_safe
  end
end
