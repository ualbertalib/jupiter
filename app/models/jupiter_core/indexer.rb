class JupiterCore::Indexer < ActiveFedora::IndexingService

  # Index the solr calculated attributes (ie stuff in Solr that doesn't end up in Fedora)
  # declared on the model
  def generate_solr_document
    super.tap do |solr_doc|
      object.owning_class.solr_calc_attributes.each do |name, metadata|
        value = object.instance_exec(&metadata[:callable])
        value.compact! if value.is_a? Array

        Solrizer.insert_field(solr_doc, name, value, metadata[:type])
      end
    end
  end

end
