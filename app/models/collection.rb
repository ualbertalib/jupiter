class Collection < JupiterCore::Base
  include Hydra::Works::CollectionBehavior

  has_property :title, ::RDF::Vocab::DC.title, solr: [:search, :facet]
  has_property :community_id, ::UalibTerms.path, solr: :path

  def path
    "#{community_id}/#{id}"
  end

  def member_works
    ActiveFedora::Base.where("member_of_paths_dpsim:#{path}")
  end

  def as_json(options)
    super(only: [:title, :id])
  end

end