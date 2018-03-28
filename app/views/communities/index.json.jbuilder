json.communities do
  json.array!(@communities) do |community|
    json.name community.title
    json.url community_path(community)
  end
end

json.collections do
  json.array!(@collections) do |collection|
    json.name collection.title
    json.url community_collection_path(collection.community, collection)
  end
end
