class Community < JupiterCore::LockedLdpObject

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where(community_id: id)
  end

end
