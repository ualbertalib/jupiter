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
    solr_doc = {:id => @export_object.id}

    self.class.indexed_attributes.each do |attr|
      roles = self.class.name_to_roles_map[attr]
      type = self.class.name_to_type_map[attr]

      raw_val = @export_object.send(attr)
      if (raw_val.is_a?(Array) && raw_val.any?(&:present?)) || raw_val.present?
        roles.each do |role|
          solr_index_name = JupiterCore::SolrNameMangler.mangled_name_for(attr, type: type, role: role)

          solr_doc[solr_index_name] = if self.class.singular_role?(role)
                                        raw_val = raw_val.first if raw_val.is_a? Array
                                        serialize_value(raw_val)
                                      else
                                        if raw_val.is_a? Array
                                          serialize_value(raw_val)
                                        else
                                          [serialize_value(raw_val)]
                                        end
                                      end
        end
      end
    end

    self.class.name_to_custom_lambda_map.each do |index_name, index_lambda|
      roles = self.class.name_to_roles_map[index_name]
      type = self.class.name_to_type_map[index_name]

      raw_val =  index_lambda.call(@export_object)
      if (raw_val.is_a?(Array) && raw_val.any?(&:present?)) || raw_val.present?
        roles.each do |role|
          solr_index_name = JupiterCore::SolrNameMangler.mangled_name_for(index_name, type: type, role: role)
          solr_doc[solr_index_name] = if self.class.singular_role?(role)
                                        raw_val = raw_val.first if raw_val.is_a? Array
                                        serialize_value(raw_val)
                                      else
                                        if raw_val.is_a? Array
                                          serialize_value(raw_val)
                                        else
                                          [serialize_value(raw_val)]
                                        end
                                      end
        end
      end
    end

    solr_doc
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

  def self.singular_role?(role)
    SINGULAR_ROLES.include? role
  end

  def serialize_value(value)
    return value if value.nil?
    klass = value.class
    if (klass == Date) ||  (klass == DateTime) || (klass == ActiveSupport::TimeWithZone)
      value = value.to_datetime if value.is_a? Date
      value.utc.iso8601(3)
    elsif klass == Array
      value.map {|v| serialize_value(v)}
    else
      value.to_s
    end
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

      self.indexed_attributes ||= []
      self.indexed_attributes << attr
    end

    def custom_index(attr, type: :string, role:, as:)
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
      self.name_to_custom_lambda_map[attr] = as
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

    private

    def inherited(child)
      super
      child.class_eval do
        custom_index :has_model, role: [:exact_match], as: ->(object) {object.class.send(:derived_af_class)}
        index :visibility, role: [:exact_match, :facet]

        index :owner, type: :integer, role: [:exact_match]

        index :record_created_at, type: :date, role: [:sort]

        index :hydra_noid, role: [:exact_match]

        index :date_ingested, type: :date, role: [:sort]
      end
    end

  end
end
