class Work < JupiterCore::Base
  # important to prepend, or other behaviour takes precedent over the superclass
	include Hydra::Works::WorkBehavior

  has_property :title, predicate: ::RDF::Vocab::DC.title, index: [:stored_searchable, :facetable]
  
  has_properties :member_of_paths, predicate: ::UalibTerms.path, index: [:descendent_path] 
  
  has_property :subject, predicate: ::RDF::Vocab::DC.subject, index: [:stored_searchable, :facetable]
  
  has_property :creator, predicate: ::RDF::Vocab::DC.creator, index: [:stored_searchable, :facetable]

  has_property :contributor, predicate: ::RDF::Vocab::DC.contributor, index: [:stored_searchable, :facetable]
  
  has_property :description, predicate: ::RDF::Vocab::DC.description, index_type: :text, index: :stored_searchable
        
  has_property :publisher, predicate: ::RDF::Vocab::DC.publisher, index: [:stored_searchable, :facetable]

  has_property :date_created, predicate: ::RDF::Vocab::DC.created, index: [:stored_searchable, :stored_sortable]

  has_property :date_modified, predicate: ::RDF::Vocab::DC.modified, index_type: :date, index: :stored_sortable


  has_property :language, predicate: ::RDF::Vocab::DC.language, index: [:stored_searchable, :facetable]

  has_property :doi, predicate: ::UalibTerms.doi, index: :symbol

  def display_properties
    super - [:member_of_paths]
  end

  def add_to_path(community_id, collection_id)
    self.member_of_paths += ["#{community_id}/#{collection_id}"]
  end
end