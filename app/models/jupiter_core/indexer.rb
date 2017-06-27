class JupiterCore::Indexer < ActiveFedora::IndexingService

  # We always want to index all known properties
  # smart defaults are good
	def generate_solr_document
		super.tap do |solr_doc|
      object.owning_class.solr_calc_attributes.each do |name, metadata|
        Solrizer.insert_field(solr_doc, name, metadata[:callable].call(object), metadata[:type])
      end
    end
	end
end