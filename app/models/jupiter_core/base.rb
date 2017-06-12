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

  # Track properties, so that we can avoid duplicating definitions in a separate indexer and on forms
	def property_names
		Work.property_names
	end

  def self.property_names
    @@property_names
  end

  def properties
    @@property_names.map do |name|
      [name, self.send(name)]
    end
  end

  def property_metadata(property_name)
    @@properties[property_name]
  end

  protected

  # a utility DSL for declaring properties which allows us to store knowledge of them.
	def self.has_properties(props = {})
		@@property_names = []
    @@properties = props

		@@properties.each do |key, value|
			@@property_names << key
      raise PropertyInvalid unless value.has_key? :predicate

      multiple = value.has_key?(:multiple) ? value[:multiple] : false

			property key, predicate: value[:predicate], multiple: multiple do |index|
        index.type value[:type] if value.has_key? :type
				index.as *value[:index] if value.has_key? :index
			end
		end
	end
end