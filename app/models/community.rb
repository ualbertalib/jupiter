class Community < JupiterCore::Base
    has_properties  :title => { 
                    predicate: ::RDF::Vocab::DC.title,
                    index: [:stored_searchable, :facetable]
                 },
                 :path => {
                   predicate: MyTerms.foo,
                   index: [:descendent_path]
                 }
end