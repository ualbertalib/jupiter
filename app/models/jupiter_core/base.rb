class JupiterCore::Base < ActiveFedora::Base

  class PropertyInvalid < StandardError; end

  SOLR_DESCRIPTOR_MAP = {
    :search => :stored_searchable,
    :sort => :stored_sortable,
    :facet => :facetable,
    :symbol => :symbol,
    :path => :descendent_path
  }

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

  def self.facet_fields
    @facets
  end

  def self.search(q='')
    response = ActiveFedora::SolrService.instance.conn.get("select", params: {q: %W|has_model_ssim:"#{self.to_s}"|, 
      facet: true,
      :'facet.field' => facet_fields.map(&:to_s)
    })

    raise SearchFailed unless response['responseHeader']['status'] == 0

    return response['response']['docs'].map {|doc| JupiterCore::LightweightResult.new(doc)}

  end

  protected

  # TODO name? ehhh
  def self.has_properties(name, predicate, attributes)
    self.has_property(name, predicate, attributes.merge!(multiple: true))
  end

  # a utility DSL for declaring properties which allows us to store knowledge of them.
  # TODO we could make this inheritable http://wiseheartdesign.com/articles/2006/09/22/class-level-instance-variables/

  # search == index.as stored_searchable
  # facet == index.as facetable
  # sort == index.as sortable
  # type == index.type
  # etc

  # descriptors == personalities. multiple index.as personalties == multiple appearances in solr doc
  # 
  # maybe special logic on the type? as they imply stored, indexed, multi
  # so add it to search?
  # or just make path its own param?

  def self.has_property(name, predicate, multiple: false, search_by_default: false, solr: [], type: :string)
    raise PropertyInvalid unless name.is_a? Symbol
    raise PropertyInvalid unless predicate.present?
    
    # TODO keep this conveinience, or push responsibility for [] onto the callsite?
    solr = [solr] unless solr.is_a? Array

    # index should contain only some combination of :search, :sort, :facet, :symbol, and :path
    # this isn't an exhaustive layering over this mess https://github.com/mbarnett/solrizer/blob/e5dd2bd571b9ebdb8a8ab214574075c28951e53e/lib/solrizer/default_descriptors.rb
    # but it helps
    raise PropertyInvalid if (solr.count {|item| ![:search, :sort, :facet, :path, :symbol].include?(item)} > 0)

    # TODO type validation

    @property_names ||= []
    @property_cache ||= {}
    @facets ||= []
    @search_fields ||= []
    @default_search_fields ||= []

    @property_names << name

    solr_name_cache ||= []
    solr.each do |descriptor| 
      solr_name_cache << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[descriptor], type: type)
    end

    @facets << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:facet], type: type) if solr.include?(:facet) 
    @facets << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:path], type: type) if solr.include?(:path)

    searchable_fields = []
    searchable_fields << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:search], type: type) if solr.include?(:search)
    searchable_fields << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:symbol], type: type) if solr.include?(:symbol)
  
    @search_fields.concat(searchable_fields)
    @default_search_fields.concat(searchable_fields) if search_by_default

    @property_cache[name] = {
      name: name,
      predicate: predicate,
      multiple: multiple,
      search_by_default: search_by_default,
      solr: solr,
      type: type,
      search_fields: @search_fields,
      default_search_fields: @default_search_fields,
      solr_names: solr_name_cache
    }

    property name, predicate: predicate, multiple: multiple do |index|
      index.type type if type.present?
      index.as *solr.map {|index| SOLR_DESCRIPTOR_MAP[index]}
    end
  end

end