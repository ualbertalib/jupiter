class JupiterCore::Base < ActiveFedora::Base

  class PropertyInvalid < StandardError; end

  # a single common indexer for all subclasses which leverages stored property metadata to DRY up indexing
  # doing this the more obvious way, but overridding self.indexer, doesn't work, as it gets
  # clobbered by the Works includes in deriving classes, so we work around this with the
  # inherited hook

  def self.inherited(child)
    class << child
      def indexer
        JupiterCore::Indexer
      end
    end
 end

 # override this to control what properties are automatically listed in the properties list
 def display_properties
  property_names
 end

  # Track properties, so that we can avoid duplicating definitions in a separate indexer and on forms
	def property_names
		self.class.property_names
	end

  def self.property_names
    @property_names
  end

  def properties
    display_properties.map do |name|
      [name.to_s, self.send(name)]
    end
  end

  def property_metadata(property_name)
    self.class.property_metadata
  end

  def self.property_metadata(property_name)
    @property_cache[property_name]
  end

  protected

  # TODO name? ehhh
  def self.has_properties(name, attributes)
    self.has_property(name, attributes.merge!(multiple: true))
  end

  # a utility DSL for declaring properties which allows us to store knowledge of them.
  # TODO we could make this inheritable http://wiseheartdesign.com/articles/2006/09/22/class-level-instance-variables/
  def self.has_property(name, attributes)
    raise PropertyInvalid unless name.is_a? Symbol
    raise PropertyInvalid unless attributes.has_key? :predicate

    @property_names ||= []
    @property_cache ||= {}


    @property_names << name
    @property_cache[name] = attributes


    multiple = attributes.has_key?(:multiple) ? attributes[:multiple] : false

    property name, predicate: attributes[:predicate], multiple: multiple do |index|
      index.type attributes[:type] if attributes.has_key? :type
      index.as *attributes[:index] if attributes.has_key? :index
    end
  end

end