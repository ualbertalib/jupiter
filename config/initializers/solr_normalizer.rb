require 'skylight'

SOLR_NORMALIZER = 'solr.query'.freeze
JUPITER_SOLR_NOTIFICATION = "jupiter.#{SOLR_NORMALIZER}".freeze

class Skylight::Core::Normalizers::SolrNormalizer < Skylight::Core::Normalizers::Normalizer

  register JUPITER_SOLR_NOTIFICATION

  def normalize(_trace, _name, payload)
    [SOLR_NORMALIZER, payload[:name], payload[:query].to_s]
  end

end
