class Exporters::Solr::IndexRoleInvalidError < StandardError; end
class Exporters::Solr::UnknownAttributeError < StandardError; end

class Exporters::Solr::BaseExporter

  attr_reader :export_object

  SOLR_FACET_ROLES = [:facet, :range_facet, :pathing].freeze
  SINGULAR_ROLES = [:sort, :range_facet].freeze

  def initialize(object)
    @export_object = object
  end

  def export
    solr_doc = {}
    self.class.indexed_attributes.each do |attr|
      roles = self.class.name_to_roles_map(attr)
      type = self.class.name_to_type_map(attr)

      raw_val = @export_object.send(attr)
      # converted_val = convert_value(raw_val, to: type)

      roles.each do |role|
        solr_index_name = JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: role)
        solr_doc[solr_index_name] = if singular_role?(role)
          raw_val = raw_val.first if raw_val.is_a? Array
          raw_val.to_s
        else
          if raw_val.is_a? Array
            raw_val.each(&:to_s)
          else
            [raw_val.to_s]
          end
        end
      end
    end

    self.class.name_to_custom_lambda_map.each do |index_name, index_lambda|
      roles = self.class.name_to_roles_map(index_name)
      type = self.class.name_to_type_map(index_name)

      raw_val =  index_lambda.call(@export_object).to_s

      roles.each do |role|
        solr_index_name = JupiterCore::SolrNameMangler.mangled_name_for(index_name, type: type, role: role)
        solr_doc[solr_index_name] = raw_val
      end
    end
  end


  def self.solr_type_for(name)
    name_to_type_map[name]
  end

  def self.solr_names_for(name)
    name_to_solr_name_map[name]
  end

  def self.solr_roles_for(name)
    name_to_roles_map[name]
  end

  def self.facet?(name)
    raise Exporters::Solr::UnknownAttributeError, "no such attribute #{name}" unless name_to_roles_map.key?(name)

    (name_to_roles_map[name] & SOLR_FACET_ROLES).present?
  end

  def self.mangled_facet_name_for(name)
    type = name_to_type_map[name]
    JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: :facet)
  end

  def self.range?(name)
    raise Exporters::Solr::UnknownAttributeError, "no such attribute #{name}" unless name_to_roles_map.key?(name)

    name_to_roles_map[name].include? :range_facet
  end

  def self.mangled_range_name_for(name)
    type = name_to_type_map[name]
    JupiterCore::SolrNameMangler.mangled_name_for(name, type: type, role: :range_facet)
  end

  class << self

    attr_accessor :reverse_solr_name_map, :name_to_type_map, :name_to_roles_map,
                  :name_to_solr_name_map, :name_to_custom_lambda_map, :indexed_attributes

    protected

    def exports(klass)
      #   @export_class = klass
    end

    def index(attr, role:, type: :string)
      role = [role] unless role.is_a? Array

      raise Exporters::Solr::IndexRoleInvalidError if role.count { |r| !JupiterCore::SolrClient.valid_solr_role?(r) } > 0

      #  raise Exporters::Solr::UnknownAttributeError, "#{@export_class} does not have an attribute named #{attr}" unless @export_class.method_defined? attr

      self.record_type(attr, type)
      self.record_roles(attr, role)

      self.reverse_solr_name_map ||= {}

      self.name_to_solr_name_map ||= {}
      self.name_to_solr_name_map[attr] = []

      role.each do |r|
        mangled_name = JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: r)
        self.reverse_solr_name_map[mangled_name] = attr
        self.name_to_solr_name_map[attr] << mangled_name
      end

      indexed_attributes ||= []
      indexed_attributes << attr
    end

    def custom_index(name, type: :string, role:, as:)
      role = [role] unless role.is_a? Array

      raise Exporters::Solr::IndexRoleInvalidError if role.count { |r| !JupiterCore::SolrClient.valid_solr_role?(r) } > 0

      self.record_type(attr, type)
      self.record_roles(attr, role)

      self.reverse_solr_name_map ||= {}

      self.name_to_solr_name_map ||= {}
      self.name_to_solr_name_map[attr] = []

      role.each do |r|
        mangled_name = JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: r)
        self.reverse_solr_name_map[mangled_name] = attr
        self.name_to_solr_name_map[attr] << mangled_name
      end

      self.name_to_custom_lambda_map ||= {}
      self.name_to_custom_lambda_map[name] = as
    end

    def record_type(name, type)
      self.name_to_type_map ||= {}
      self.name_to_type_map[name] = type
    end

    def record_roles(name, roles)
      self.name_to_roles_map ||= {}
      self.name_to_roles_map[name] = roles
    end

    def attribute_index?(name)
      self.indexed_attributes.include? name
    end

    def custom_index?(name)
      self.name_to_custom_lambda_map.key? name
    end

    def singular_role(role)
      SINGULAR_ROLES.include? role
    end

  end

end
