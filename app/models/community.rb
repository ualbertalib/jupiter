class Community < JupiterCore::Base
  has_property :title, predicate: ::RDF::Vocab::DC.title, index: [:stored_searchable, :facetable]

  def member_collections
    ActiveFedora::Base.where("community_id_dpsim:#{id}")
  end
end