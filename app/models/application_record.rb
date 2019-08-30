class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  # this isn't a predicate name you daft thing
  # rubocop:disable Naming/PredicateName
  def self.has_solr_exporter(klass)
    class << self
      attr_accessor :solr_exporter_class
    end
    define_method :solr_exporter do
      return self.class.solr_exporter_class.new(self)
    end

    self.solr_exporter_class = klass
    after_commit :update_solr
  end
  # rubocop:enable Naming/PredicateName

  def update_solr
    solr_doc = solr_exporter.export
    JupiterCore::SolrServices::Client.instance.add_or_update_document(solr_doc)
  end

end
