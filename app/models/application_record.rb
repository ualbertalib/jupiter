class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  def self.has_solr_exporter(klass)
    # class << self
    #   attr_accessor :solr_calc_attributes, :facets, :ranges
    # end
    # self.solr_calc_attributes = {}
    # self.facets = []
    # self.ranges = []

    class << self
      attr_accessor :solr_exporter_class
    end
    define_method :solr_exporter do
      return self.class.solr_exporter_class.new(self)
    end

    self.solr_exporter_class = klass
    after_commit :update_solr



    # import some information from the Solr Exporter for compatibility purposes with existing Fedora stuff
    # TODO: remove
    # @solr_exporter_class.custom_indexes.each do |name|
    #   type = @solr_exporter_class.solr_type_for(name)
    #   solr_name_cache = @solr_exporter_class.solr_names_for(name)
    #   self.facets << @solr_exporter_class.mangled_facet_name_for(name) if @solr_exporter_class.facet?(name)
    #   self.ranges << @solr_exporter_class.mangled_range_name_for(name) if @solr_exporter_class.range?(name)
    #
    #   self.solr_calc_attributes[name] = {
    #     solrize_for: @solr_exporter_class.solr_roles_for(name),
    #     type: type,
    #     solr_names: solr_name_cache
    #   }
    # end
  end

  def update_solr
    solr_doc = self.solr_exporter.export
    JupiterCore::SolrServices::Client.instance.add_or_update_document(solr_doc)
  end
end
