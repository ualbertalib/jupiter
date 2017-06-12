class Collection < JupiterCore::Base
  include Hydra::Works::CollectionBehavior

  # TODO A real predicate for this -- mb
  class MyTerms < ::RDF::Vocabulary("http://terms.library.ualberta.ca/id/")
    term :foo
  end

  has_properties  :title => { 
                    predicate: ::RDF::Vocab::DC.title,
                    index: [:stored_searchable, :facetable]
                 },
                 :community_path => {
                   predicate: MyTerms.foo,
                   index: [:descendent_path]
                 }

end