class Community < JupiterCore::Base
  has_property :title,::RDF::Vocab::DC.title, solr: [:search, :facet]

  def member_collections
    ActiveFedora::Base.where("community_id_dpsim:#{id}")
  end
end