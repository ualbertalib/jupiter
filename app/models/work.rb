class Work < JupiterCore::Base
  # important to prepend, or other behaviour takes precedent over the superclass
	include Hydra::Works::WorkBehavior

  has_property :title, ::RDF::Vocab::DC.title, solr: [:search, :facet]
  
  has_properties :member_of_paths, ::UalibTerms.path, solr: :path
  
  has_property :subject, ::RDF::Vocab::DC.subject, solr: [:search, :facet]
  
  has_property :creator, ::RDF::Vocab::DC.creator, solr: [:search, :facet]

  has_property :contributor, ::RDF::Vocab::DC.contributor, solr: [:search, :facet]
  
  has_property :description, ::RDF::Vocab::DC.description, type: :text, solr: :search
        
  has_property :publisher, ::RDF::Vocab::DC.publisher, solr: [:search, :facet]

  has_property :date_created, ::RDF::Vocab::DC.created, solr: [:search, :sort]

  has_property :date_modified, ::RDF::Vocab::DC.modified, type: :date, solr: :sort

  has_property :language, ::RDF::Vocab::DC.language, solr: [:search, :facet]

  has_property :doi,  ::UalibTerms.doi, solr: :symbol

  def display_properties
    super - [:member_of_paths]
  end

  def add_to_path(community_id, collection_id)
    self.member_of_paths += ["#{community_id}/#{collection_id}"]
  end
end