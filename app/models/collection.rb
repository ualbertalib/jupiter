class Collection < JupiterCore::LockedLdpObject
  ldp_object_includes Hydra::Works::CollectionBehavior

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
  has_attribute :community_id, ::UalibTerms.path, solrize_for: :pathing

  def path
    "#{community_id}/#{id}"
  end

  def member_works
    Work.where(member_of_paths: path)
  end

  def as_json(options)
    super(only: [:title, :id])
  end

end