class Collection < JupiterCore::Base
  include Hydra::Works::CollectionBehavior

  has_property :title, predicate: ::RDF::Vocab::DC.title, index: [:stored_searchable, :facetable]
  has_property :community_id, predicate: ::UalibTerms.path, index: [:descendent_path]

  def path
    "#{community_id}/#{id}"
  end

  def member_works
    ActiveFedora::Base.where("member_of_paths_dpsim:#{path}")
  end

end