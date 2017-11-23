module CommunitiesCollectionsTypeahead
  def typeahead_results(term)
    results = []
    if term.present?
      communities = JupiterCore::Search.faceted_search(q: "title_tesim:#{term}*",
                                                       models: [Community], as: current_user)
                                       .sort(:title, :asc)
                                       .map do |c|
        { id: c.id, text: c.title, path: path_to_community(c) }
      end
      if communities.any?
        results.append(text: 'Communities', children: communities)
      end
      # TODO: sort by community name first, collection name second (see Issue #276)
      collections = JupiterCore::Search.faceted_search(q: "title_tesim:#{term}*",
                                                       models: [Collection], as: current_user)
                                       .sort(:title, :asc)
                                       .map do |c|
        { id: c.id, text: "#{c.community.title} -- #{c.title}", path: path_to_collection(c) }
      end
      if collections.any?
        results.append(text: 'Collections', children: collections)
      end
    end
    results
  end

  private

  # Note: these get overridden in admin communities controller
  def path_to_community(community)
    community_path(community)
  end

  def path_to_collection(collection)
    community_collection_path(collection.community, collection)
  end
end
