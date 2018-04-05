require 'skylight'

SOLR_NORMALIZER = 'solr.query'.freeze
JUPITER_SOLR_NOTIFIFCATION = "jupiter.#{SOLR_NORMALIZER}".freeze

class Skylight::Normalizers::SolrNormalizer < Skylight::Normalizers::Normalizer

  register JUPITER_SOLR_NOTIFIFCATION

  def normalize(_trace, _name, payload)
    [SOLR_NORMALIZER, payload[:name], payload[:query].to_s]
  end

end
