class JupiterCore::Indexer < ActiveFedora::IndexingService

  # We always want to index all known properties
  # smart defaults are good
	def generate_solr_document
    super
		super.tap do |solr_doc|
      object.properties.each do |key, value|
        solr_doc[object.class.solr_property_name(key)] = object.send(key)
      end
    end
	end
end