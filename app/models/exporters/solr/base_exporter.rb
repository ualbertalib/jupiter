class Exporters::Solr::IndexRoleInvalidError < StandardError; end
class Exporters::Solr::UnknownAttributeError < StandardError; end

class Exporters::Solr::BaseExporter
  class_attributes :solr_attributes, :reverse_solr_name_cache, :solr_calc_attributes
  attr_reader :export_object

  def initialize(object)
    @export_object = object
  end

  class << self
    protected

    def exports(klass)
      @export_class = klass
    end

    def index(attr, role:, type: :string)
      role = [role] unless role.is_a? Array

      raise Exporters::Solr::IndexRoleInvalidError if role.count { |r| !JupiterCore::SolrClient.valid_solr_role?(r) } > 0
    #  raise Exporters::Solr::UnknownAttributeError, "#{@export_class} does not have an attribute named #{attr}" unless @export_class.method_defined? attr


    end

    def virtual_index(name, role:, as:)
    end
  end

end
