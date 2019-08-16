class JupiterCore::SolrServices::Client

  include Singleton

  SOLR_CONFIG = YAML.safe_load(ERB.new(File.read(Rails.root.join('config', 'solr.yml'))).result,
                               [], [], true)[Rails.env].symbolize_keys

  def connection
    @connection ||= RSolr.connect url: SOLR_CONFIG[:url]
  end

  def add_or_update_document(solr_doc)
    # it's questionable whether this "softCommit" param does anything at all, but I'm bringing it over from Solrizer
    # for the moment. We can revist later.
    #
    # if the params arg is missing for some reason, like you call connection.add(solr_doc, softCommit: true)
    # RSolr silently does nothing. Extremely cool and helpful behaviour.
    connection.add(solr_doc, params: { softCommit: true })
  end

end
