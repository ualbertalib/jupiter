class JupiterCore::Indexer < ActiveFedora::IndexingService

  # We always want to index all known properties
  # smart defaults are good
	def generate_solr_document
		super.tap do |solr_doc|
      object.owning_class.attribute_names.each do |name|
        metadata = object.owning_class.attribute_metadata(name)
        metadata[:solr_names].each do |solr_name| 
          solr_doc[solr_name] = object.send(name)
        end
      end
    end
	end
end