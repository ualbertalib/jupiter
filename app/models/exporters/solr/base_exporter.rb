# Some useful errors
class Exporters::Solr::IndexRoleInvalidError < StandardError; end
class Exporters::Solr::UnknownAttributeError < StandardError; end

# This is the base class for all other Solr Export classes. Handles
# all of the heavy lifting so that implementing a new item type's solr
# representation just requires focusing on the DSL of declaring indexes
class Exporters::Solr::BaseExporter

  attr_reader :export_object

  SOLR_FACET_ROLES = [:facet, :range_facet, :pathing].freeze
  SINGULAR_ROLES = [:sort, :range_facet].freeze

  def initialize(object)
    @export_object = object
  end

  # Generates a hash suitable for writing to Solr, of the form {solr_index_name => value from the object we're exporting},
  # where the index names are mangled according to the index type & role declarations to
  # meet the wildcard index names declared in solr/schema.xml. See models/jupiter_core/solr_services/name_mangling
  # for details as to the way names are mangled.
  def export
    solr_doc = { id: @export_object.id }

    self.class.indexed_attributes.each do |attr|
      roles = self.class.name_to_roles_map[attr]
      type = self.class.name_to_type_map[attr]

      raw_val = @export_object.send(attr)
      solr_doc = add_role_values_to_solr_doc(solr_doc, attr, type, roles, raw_val)
    end

    self.class.name_to_custom_lambda_map.each do |index_name, index_lambda|
      roles = self.class.name_to_roles_map[index_name]
      type = self.class.name_to_type_map[index_name]

      raw_val = index_lambda.call(@export_object)

      solr_doc = add_role_values_to_solr_doc(solr_doc, index_name, type, roles, raw_val)
    end

    solr_doc
  end

  def search_term_for(attr)
    self.class.search_term_for(attr, @export_object.send(attr))
  end

  def self.search_term_for(attr, value, role: :search)
    raise ArgumentError, "search value can't be nil" if value.nil?

    solr_attr_name = self.solr_name_for(attr, role: role)
    %Q(#{solr_attr_name}:"#{value}")
  end

  def facet_term_for(attr_name)
    self.class.facet_term_for(attr_name, @export_object.send(attr_name))
  end

  def self.facet_term_for(attr_name, value, role: :facet)
    raise ArgumentError, "search value can't be nil" if value.nil?

    solr_attr_name = solr_name_for(attr_name, role: role)
    return { solr_attr_name => { begin: value, end: value } } if role == :range_facet

    { solr_attr_name => [value].flatten }
  end

  # basic information lookups leveraged by various pieces of our ActiveFedora wrapper and
  # search infrastructure
  def self.solr_type_for(name)
    name_to_type_map[name]
  end

  def self.solr_names_for(name)
    name_to_solr_name_map[name]
  end

  def self.solr_name_for(name, role:)
    type = name_to_type_map[name]
    JupiterCore::SolrServices::NameMangling.mangled_name_for(name, type: type, role: role)
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
    roles = name_to_roles_map[name]
    facet_role = roles.detect { |r| SOLR_FACET_ROLES.include? r }
    JupiterCore::SolrServices::NameMangling.mangled_name_for(name, type: type, role: facet_role)
  end

  def self.range?(name)
    raise Exporters::Solr::UnknownAttributeError, "no such attribute #{name}" unless name_to_roles_map.key?(name)

    name_to_roles_map[name].include? :range_facet
  end

  def self.mangled_range_name_for(name)
    type = name_to_type_map[name]
    JupiterCore::SolrServices::NameMangling.mangled_name_for(name, type: type, role: :range_facet)
  end

  def self.name_for_mangled_name(mangled_name)
    reverse_solr_name_map[mangled_name]
  end

  def self.singular_role?(role)
    SINGULAR_ROLES.include? role
  end

  def self.custom_indexes
    name_to_custom_lambda_map.keys
  end

  def self.indexed_has_model_name
    @indexed_model_name
  end

  protected

  # provide a consistent representation of values in Solr, based on what we were doing previously with solrizer
  def serialize_value(value)
    return value if value.nil?

    klass = value.class
    if (klass == Date) || (klass == DateTime) || (klass == ActiveSupport::TimeWithZone)
      value = value.to_datetime if value.is_a? Date
      value.utc.iso8601(3)
    elsif klass == Array
      value.map { |v| serialize_value(v) }
    else
      value.to_s
    end
  end

  # insert the given value into the solr_doc with the right representation for each
  # index associated with the attribute's declared type and index roles
  def add_role_values_to_solr_doc(solr_doc, attr, type, roles, raw_val)
    return solr_doc unless (raw_val.is_a?(Array) && raw_val.any?(&:present?)) || raw_val.present?

    roles.each do |role|
      solr_index_name = JupiterCore::SolrServices::NameMangling.mangled_name_for(attr, type: type, role: role)

      solr_doc[solr_index_name] = if self.class.singular_role?(role)
                                    raw_val = raw_val.first if raw_val.is_a? Array
                                    serialize_value(raw_val)
                                  elsif raw_val.is_a? Array
                                    serialize_value(raw_val)
                                  else
                                    [serialize_value(raw_val)]
                                  end
    end
    solr_doc
  end

  class << self

    attr_accessor :reverse_solr_name_map, :name_to_type_map, :name_to_roles_map,
                  :name_to_solr_name_map, :name_to_custom_lambda_map, :indexed_attributes, :searched_solr_names,
                  :facets, :ranges, :default_sort_direction, :default_sort_indexes, :default_ar_sort_args

    protected

    def indexed_model_name(name)
      @indexed_model_name = name
    end

    # the basic DSL for declaring Solr indexes who will take their contents from attributes
    # declared on the objects we will export
    def index(attr, role:, type: :string)
      role = [role] unless role.is_a? Array

      if role.count { |r| !JupiterCore::SolrServices.valid_solr_role?(r) } > 0
        raise Exporters::Solr::IndexRoleInvalidError
      end

      record_type(attr, type)
      record_roles(attr, role)
      record_solr_names(attr, type, role)

      self.indexed_attributes ||= []
      self.indexed_attributes << attr
    end

    # DSL for declaring custom indexes, where the value isn't taken from a pre-existing
    # attribute but instead is determined by a given lambda
    #
    # Sorry rubocop, but you index something *AS* something. It's communicative.
    # rubocop:disable Naming/UncommunicativeMethodParamName
    def custom_index(attr, type: :string, role:, as:)
      role = [role] unless role.is_a? Array

      if role.count { |r| !JupiterCore::SolrServices.valid_solr_role?(r) } > 0
        raise Exporters::Solr::IndexRoleInvalidError
      end

      record_type(attr, type)
      record_roles(attr, role)
      record_solr_names(attr, type, role)

      self.name_to_custom_lambda_map ||= {}
      self.name_to_custom_lambda_map[attr] = as
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

    def default_sort(index:, direction:)
      @default_ar_sort_args = {index => direction}
      index = [index] unless index.is_a?(Array)
      direction = [direction] unless direction.is_a?(Array)
      self.default_sort_indexes = index.map { |idx| solr_name_for(idx, role: :sort) }
      self.default_sort_direction = direction
    end

    def record_type(name, type)
      self.name_to_type_map ||= {}
      self.name_to_type_map[name] = type
    end

    def record_roles(name, roles)
      self.name_to_roles_map ||= {}
      self.name_to_roles_map[name] = roles
    end

    def record_solr_names(attr, type, roles)
      self.reverse_solr_name_map ||= {}

      self.name_to_solr_name_map ||= {}
      self.name_to_solr_name_map[attr] = []

      self.searched_solr_names ||= []
      self.facets ||= []
      self.ranges ||= []

      roles.each do |r|
        mangled_name = JupiterCore::SolrServices::NameMangling.mangled_name_for(attr, type: type, role: r)
        self.reverse_solr_name_map[mangled_name] = attr
        self.name_to_solr_name_map[attr] << mangled_name
        self.searched_solr_names << mangled_name if r == :search
        self.facets << mangled_name if SOLR_FACET_ROLES.include?(r)
        self.ranges << mangled_name if r == :range_facet
      end
      self.searched_solr_names.uniq!
      self.facets.uniq!
      self.ranges.uniq!
    end

    def attribute_index?(name)
      self.indexed_attributes.include? name
    end

    def custom_index?(name)
      self.name_to_custom_lambda_map.key? name
    end

    private

    # add indexes for some very low level attributes that we inject into all subclasses of LockedLDPObject,
    # just to save on exporters having to declare these "universal" attributes manually.
    def inherited(child)
      super
      child.class_eval do
        custom_index :has_model, role: [:exact_match], as: lambda { |object| @indexed_model_name }

        # The original Fedora property was called 'owner' even though it held an id, so for compatibility
        # we keep that index name here
        custom_index :owner, type: :integer, role: [:exact_match], as: lambda { |object| object.owner_id }

        index :visibility, role: [:exact_match, :facet]

        index :record_created_at, type: :date, role: [:sort]

        index :hydra_noid, role: [:exact_match]

        index :date_ingested, type: :date, role: [:sort]
      end
    end

  end

end
