class JupiterCore::Indexer < ActiveFedora::IndexingService

  # Index the solr calculated attributes (ie stuff in Solr that doesn't end up in Fedora)
  # declared on the model
  #
  # Rubocop this cop literally breaks the code
  # rubocop:disable Rails/TimeZone
  def generate_solr_document
    exporter = object.owning_object.solr_exporter

    solr_doc = exporter.export

    # These two attributes only appear in Solr, not ActiveFedora, and were managed by
    # Solrizer for some random reason. Recreated here for compatibility in this stage of the refactoring
    # The logic behind them seems squirly and we have other attributes that track equivalent data. I'm
    # keeping these around solely to avoid breaking any ActiveFedora expectations at this stage.
    #
    # TODO: remove

    m_time = object.modified_date.presence || DateTime.now
    m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)

    solr_doc['system_modified_dtsi'] = m_time.utc.iso8601

    c_time = object.create_date.presence || DateTime.now
    c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)

    solr_doc['system_create_dtsi'] = c_time.utc.iso8601

    solr_doc
  end
  # rubocop:enable Rails/TimeZone

end
