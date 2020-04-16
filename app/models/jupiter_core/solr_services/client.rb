class JupiterCore::SolrServices::Client

  include Singleton

  SOLR_CONFIG = YAML.safe_load(ERB.new(File.read(Rails.root.join('config/solr.yml'))).result,
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

  # IN FACT, if the params arg is missing for ANY OF THESE, RSolr silently does nothing.
  #
  # Go on, ask me how much fun this was to debug
  def remove_document(id)
    connection.delete_by_id(id, params: { softCommit: true })
  end

  def truncate_index
    connection.delete_by_query('*:*', params: { softCommit: true })
  end

  def truncate_index_with_suffix
    connection.delete_by_query("has_model_ssim:*_#{JupiterCore::SolrServices.index_suffix}", params: { softCommit: true })
  end
end
