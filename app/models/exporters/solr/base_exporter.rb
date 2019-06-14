class Exporters::Solr::IndexRoleInvalidError < StandardError; end
class Exporters::Solr::UnknownAttributeError < StandardError; end

class Exporters::Solr::BaseExporter

  attr_reader :export_object

  SOLR_FACET_ROLES = [:facet, :range_facet, :pathing]

  def initialize(object)
    @export_object = object
  end

  def self.solr_type_for(name)
    name_to_type_map[name]
  end

  def self.solr_names_for(name)
    self.name_to_solr_name_map[name]
  end

  def self.solr_roles_for(name)
    self.name_to_roles_map[name]
  end

  def self.is_facet?(name)
    return Exporters::Solr::UnknownAttributeError unless name_to_roles_map.key?(name)
    return (name_to_roles_map[name] & SOLR_FACET_ROLES).present?
  end

  def self.mangled_facet_name_for(name)
    type = self.name_to_type_map[name]
    JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: :facet)
  end

  def self.is_range?(name)
    return Exporters::Solr::UnknownAttributeError unless name_to_roles_map.key?(name)
    return name_to_roles_map[name].include? :range_facet
  end

  def self.mangled_range_name_for(name)
    type = self.name_to_type_map[name]
    JupiterCore::SolrNameMangler.mangled_name_for(name, type: type, role: :range_facet)
  end


  class << self
    attr_accessor :reverse_solr_name_map, :solr_calc_attributes, :name_to_type_map, :name_to_roles_map, :name_to_solr_name_map

    protected

    def exports(klass)
   #   @export_class = klass
    end

    def index(attr, role:, type: :string)
      role = [role] unless role.is_a? Array

      raise Exporters::Solr::IndexRoleInvalidError if role.count { |r| !JupiterCore::SolrClient.valid_solr_role?(r) } > 0
    #  raise Exporters::Solr::UnknownAttributeError, "#{@export_class} does not have an attribute named #{attr}" unless @export_class.method_defined? attr

      self.reverse_solr_name_map ||= {}

      self.name_to_type_map ||= {}
      self.name_to_type_map[attr] = type

      self.name_to_roles_map ||= {}
      self.name_to_roles_map[attr] = role

      self.name_to_solr_name_map ||= {}
      self.name_to_solr_name_map[attr] = []

      role.each do |r|
        mangled_name = JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: r)
        self.reverse_solr_name_map[mangled_name] = attr
        self.name_to_solr_name_map[attr] << mangled_name
      end
    end

    def virtual_index(name, role:, as:)
    end
  end

end
