class Community < JupiterCore::CachedLdpObject
  has_attribute :title,::RDF::Vocab::DC.title, solrize_for: [:search, :facet]

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where('community_id_dpsim' => id)
  end
end