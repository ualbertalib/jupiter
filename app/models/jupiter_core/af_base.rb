class JupiterCore::AfBase < ActiveFedora::Base

  attr_accessor :owning_object

  validate :visibility_must_be_known
  validates :owner, presence: true
  validates :record_created_at, presence: true

  before_validation :set_record_created_at, on: :create

  # ActiveFedora gives us system_create_dtsi, but that only exists in Solr, because what everyone wants
  # is a created_at that jumps around when you rebuild your index
  def set_record_created_at
    self.record_created_at = Time.current.utc.iso8601(3)
  end

  def visibility_must_be_known
    return true if visibility.present? && owning_object.class.valid_visibilities.include?(visibility)
    errors.add(:visibility, I18n.t('locked_ldp_object.errors.invalid_visibility', visibility: visibility))
  end

  # this is the nice version of coerce_value. This is used for data going _in_ to Fedora/Solr, so it
  # sanity checks the conversion. coerce_value blindly does the conversion, for assumed-good data being
  # read back from Fedora/Solr
  def convert_value(value, to:)
    return value if value.nil?
    case to
    when :string, :text
      unless value.is_a?(String)
        raise TypeError, "#{value} isn't a String. Call to_s explicitly if "\
                         "that's what you want"
      end
      value
    when :date
      # ActiveFedora/RDF does the wrong thing with Time (see below) AND
      # it serializes every other Date type to a string internally at a very low precision (second granularity)
      # so we convert all date types into strings ourselves to bypass ActiveFedora's serialization, and then
      # use our modifications to Solrizer to save them in solr in a proper date index.
      value = value.to_datetime if value.is_a?(Date)
      if value.is_a?(String)
        value
      elsif value.respond_to?(:iso8601)
        value.utc.iso8601(3)
      else
        raise TypeError, "#{value} is not a Date type"
      end
    when :bool
      raise TyperError, "#{value} is not a boolean" unless [true, false].include?(value)
      value
    when :int
      raise TypeError, "#{value} is not a integer value" unless value.is_a?(Integer)
      value
    when :path
      value
    when :json_array
      raise TypeError, "#{value} is not an Array" unless value.is_a?(Array)
      value.to_json
    when :float
      raise TypeError, "#{value} is not a float value" unless value.is_a?(Float)
      value
    else
      raise 'NOT IMPLEMENTED'
    end
  end

  # Paper over a 2 year old bug in ActiveFedora where it simply SILENTLY IGNORES validation callbacks
  # (https://github.com/samvera/active_fedora/issues/914)
  # ...
  # don't try to write your own ORM, kids
  def run_validations!
    run_callbacks(:validation) do
      super
    end
  end

  def owning_class
    self.class.owning_class
  end

  class << self

    attr_reader :owning_class

  end

  # a single common indexer for all subclasses which leverages stored property metadata to DRY up indexing
  def self.indexer
    JupiterCore::Indexer
  end

  # Utility method for creating validations based on controlled vocabularies
  def uri_validation(value, attribute, vocabulary = nil)
    # Most (all?) of the time the controlled vocabulary is named after the attribute
    vocabulary = attribute if vocabulary.nil?
    return true if ::CONTROLLED_VOCABULARIES[vocabulary].any? { |term| term[:uri] == value }
    errors.add(attribute, :not_recognized)
    false
  end

  # Methods defined on the +owning_object+ can be called by the "unlocked" methods defined on the ActiveFedora
  # object
  def method_missing(name, *args, &block)
    return owning_object.send(name, *args, &block) if owning_object.respond_to?(name, true)
    super
  end

  def respond_to_missing?(name, include_private = false)
    owning_object.respond_to?(name, include_private) || super
  end

end
