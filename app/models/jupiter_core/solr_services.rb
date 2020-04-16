module JupiterCore::SolrServices
  extend ActiveSupport::Autoload

  SOLR_ROLES = [:search, :sort, :facet, :exact_match, :pathing, :range_facet].freeze
  SOLR_TYPES = [:string, :text, :path, :boolean, :date, :integer, :float, :json_array].freeze

  class NameManglingError < StandardError; end

  class << self
    attr_accessor :index_suffix
  end

  def self.valid_solr_type?(type)
    SOLR_TYPES.include?(type)
  end

  def self.valid_solr_role?(role)
    SOLR_ROLES.include?(role)
  end
end
