class Work < JupiterCore::Base
  # important to prepend, or other behaviour takes precedent over the superclass
	include Hydra::Works::WorkBehavior

  has_property :title, ::RDF::Vocab::DC.title, search: true, facet: true
  
  has_properties :member_of_paths, ::UalibTerms.path, index: [:descendent_path] 
  
  has_property :subject, ::RDF::Vocab::DC.subject, search: true, facet: true
  
  has_property :creator, ::RDF::Vocab::DC.creator, search: true, facet: true

  has_property :contributor, ::RDF::Vocab::DC.contributor, search: true, facet: true
  
  has_property :description, ::RDF::Vocab::DC.description, index_type: :text, search: true
        
  has_property :publisher, ::RDF::Vocab::DC.publisher, search: true, facet: true

  has_property :date_created, ::RDF::Vocab::DC.created, search: true, sort: true

  has_property :date_modified, ::RDF::Vocab::DC.modified, index_type: :date, sort: true

  has_property :language, ::RDF::Vocab::DC.language, search: true, facet: true

  has_property :doi,  ::UalibTerms.doi, index: :symbol

  def display_properties
    super - [:member_of_paths]
  end

  def add_to_path(community_id, collection_id)
    self.member_of_paths += ["#{community_id}/#{collection_id}"]
  end
end