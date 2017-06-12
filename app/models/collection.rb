class Collection < JupiterCore::Base
  include Hydra::Works::CollectionBehavior

  # TODO A real predicate for this -- mb
  class MyTerms < ::RDF::Vocabulary("http://terms.library.ualberta.ca/id/")
    term :foo
  end

  has_property :title, predicate: ::RDF::Vocab::DC.title, index: [:stored_searchable, :facetable]
  has_property :community_id, predicate: MyTerms.foo, index: [:descendent_path]

  def path
    "#{community_id}/#{id}"
  end

  def member_works
    ActiveFedora::Base.where("member_of_paths_dpsim:#{path}")
  end

end