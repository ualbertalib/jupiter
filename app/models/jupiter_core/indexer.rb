class JupiterCore::Indexer < ActiveFedora::IndexingService

  # Index the solr calculated attributes (ie stuff in Solr that doesn't end up in Fedora)
  # declared on the model
  def generate_solr_document
    if object.owning_object.class.solr_exporter_class.present?
      exporter = object.owning_object.solr_exporter

      solr_doc = exporter.export

      # These two attributes only appear in Solr, not ActiveFedora, and were managed by
      # Solrizer for some random reason. Recreated here for compatibility in this stage of the refactoring
      #
      # TODO: remove

      m_time = object.modified_date.present? ? object.modified_date : DateTime.now
      m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)

      solr_doc['system_modified_dtsi'] = m_time.utc.iso8601

      c_time = object.create_date.present? ? object.create_date : DateTime.now
      c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)

      solr_doc['system_create_dtsi'] = c_time.utc.iso8601

      solr_doc
    else
      # old-style Solrizer generation of solr document
      super.tap do |solr_doc|
        object.owning_class.solr_calc_attributes.each do |name, metadata|
          value = object.instance_exec(&metadata[:callable])
          value.compact! if value.is_a? Array
          metadata[:solr_descriptors].each do |descriptor|
            Solrizer.insert_field(solr_doc, name, value, descriptor)
          end
        end
      end
    end
  end

end
