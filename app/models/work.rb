class Work < JupiterCore::Base
  # important to prepend, or other behaviour takes precedent over the superclass
	include Hydra::Works::WorkBehavior

    # TODO A real predicate for this -- mb
  class MyTerms < ::RDF::Vocabulary("http://terms.library.ualberta.ca/id/")
    term :foo
  end


  has_properties :title => { 
                    predicate: ::RDF::Vocab::DC.title,
                    index: [:stored_searchable, :facetable]
                 },
                 :collection_path => {
                   predicate: MyTerms.foo,
                   index: [:descendent_path] 
                 }

 #  property :trid, predicate: ::UALId.trid, multiple: false do |index|
 #    index.as :stored_searchable, :sortable
 #  end
 #  property :ser, predicate: ::UALId.ser, multiple: false do |index|
 #    index.as :stored_searchable, :sortable
 #  end

 #  property :temporal, predicate: ::RDF::DC.temporal  do |index|
 #    index.as :stored_searchable, :facetable
 #  end

 #  property :spatial, predicate: ::RDF::DC.spatial do |index|
 #    index.as :stored_searchable, :facetable
	# end

 #  property :is_version_of, predicate: ::RDF::DC.isVersionOf, multiple:false do |index|
 #    index.as :stored_searchable
 #  end

  # property :unicorn, predicate: ::UALId.unicorn, multiple: false do |index|
  #   index.as :stored_searchable
  # end

  # property :fedora3uuid, predicate: ::UALId.fedora3uuid, multiple: false do |index|
  #   index.as :symbol, :stored_searchable
  # end

  # property :fedora3handle, predicate: ::UALId.fedora3handle, multiple: false do |index|
  #   index.as :symbol, :stored_searchable
  # end

  # property :ingestbatch, predicate: ::UALTerms.ingestbatch, multiple: false do |index|
  #   index.as :stored_searchable
  # end

  # property :hasCollection, predicate: ::UALTerms.hasCollection do |index|
  #   index.as :symbol, :stored_searchable
  # end

  # property :belongsToCommunity, predicate: ::UALTerms.belongsToCommunity, multiple: true do |index|
  #   index.as :symbol, :stored_searchable
  # end

  # property :hasCollectionId, predicate: ::UALTerms.hasCollectionId do |index|
  #   index.as :symbol, :stored_searchable
  # end

  # begin
  #   LocalAuthority.register_vocabulary(self, "spatial", "geonames_cities")
  # rescue
  #   puts "tables for vocabularies missing"
  # end

  # property :year_created, predicate: ::UALTerms.year_created, multiple: false do |index|
  #   index.type :date
  #   index.as :stored_searchable, :facetable
  # end

  # property :remote_resource, predicate: ::UALTerms.remote_resource, multiple:false

  # property :doi, predicate: ::UALId.doi, multiple: false do |index|
  #   index.as :symbol
  # end
end