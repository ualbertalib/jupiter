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

  def self.solr_property_name(property_name)
    @solrized_name[property_name]
  end

  protected

  # TODO name? ehhh
  def self.has_properties(name, predicate, attributes)
    self.has_property(name, predicate, attributes.merge!(multiple: true))
  end

  # a utility DSL for declaring properties which allows us to store knowledge of them.
  # TODO we could make this inheritable http://wiseheartdesign.com/articles/2006/09/22/class-level-instance-variables/


  # the solrizer & associate code is a mess of confusion eg. stored searchable = 
  # https://github.com/mbarnett/solrizer/blob/e5dd2bd571b9ebdb8a8ab214574075c28951e53e/lib/solrizer/default_descriptors.rb

  # search == index.as stored_searchable
  # facet == index.as facetable
  # sort == index.as sortable
  # type == index.type

  # TODO descendant paths don't map to this well
  # TODO puzzle out index as

  # descriptors == personalities. multiple index.as personalties == multiple appearances in solr doc
  # 
  # maybe special logic on the type? as they imply stored, indexed, multi
  # so add it to search?
  # or just make path its own param?

  def self.has_property(name, predicate, multiple: false, search: false, facet: false, sort: false, type: :symbol)
    raise PropertyInvalid unless name.is_a? Symbol
    raise PropertyInvalid unless predicate.present?
    raise PropertyInvalid unless [true, false, :default].include?(search)
    raise PropertyInvalid unless [true, false].include?(facet)
    raise PropertyInvalid unless [true, false].include?(sort)
    # todo type validation

    @property_names ||= []
    @property_cache ||= {}
    @facets ||= []
    @search_fields ||= []
    @solrized_name ||= {}

    @property_names << name
    @property_cache[name] = attributes

    # todo change dsl: search => true, facet => true, do all the heavy lifting here
    @facets << name if (attributes.has_key?(:index) && (attributes[:index] == :facetable) || attributes.include?(:facetable))
    @search_fields << name if attributes[:search_by_default] == true

    # todo cleanup
    index = attributes[:index].is_a?(Array) ? attributes[:index].first : attributes[:index]

    # todo what should the "default" index type be?
    @solrized_name[name] = Solrizer.solr_name(name, index, type: (attributes[:type] || :symbol))

    multiple = attributes.has_key?(:multiple) ? attributes[:multiple] : false

    property name, predicate: predicate, multiple: multiple do |index|
      index.type attributes[:type] if attributes.has_key? :type
      index.as *attributes[:index] if attributes.has_key? :index
    end
  end

end