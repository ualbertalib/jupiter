class JupiterCore::SolrClient
  include Singleton

  SOLR_CONFIG = YAML.safe_load(ERB.new(File.read("#{Rails.root}/config/solr.yml")).result, [], [], true)[Rails.env].symbolize_keys

  def connection
    @solr_connection ||= RSolr.connect :url => SOLR_CONFIG[:url]
  end
end
