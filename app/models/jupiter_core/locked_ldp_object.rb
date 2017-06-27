# JupiterCore::Base classes are lightweight, read-only objects
module JupiterCore
  class ObjectNotFound < StandardError; end

  class LockedLdpObject
    class PropertyInvalidError < StandardError; end
    class MultipleIdViolationError < StandardError; end
    class AlreadyDefinedError < StandardError; end
    class LockedInstanceError < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Serializers::JSON

    AF_CLASS_PREFIX = 'IR'

    SOLR_DESCRIPTOR_MAP = {
      :search => :stored_searchable,
      :sort => :stored_sortable,
      :facet => :facetable,
      :exact_match => :symbol,
      :pathing => :descendent_path
    }

    private_class_method :new

    # inheritable class attributes (not all class-level attributes in this class should be inherited, 
    # these are the inheritance-safe attributes)
    class_attribute :af_parent_class, :attribute_cache, :attribute_names, :facets, 
                    :reverse_solr_name_cache, :solr_calc_attributes

    attr_reader :solr_representation

    def id
      return ldp_object.send(:id) if ldp_object.present?
      solr_representation['id'] if solr_representation
    end

    def unlock_and_fetch_ldp_object(&block)
      self.ldp_object = self.class.derived_af_class.find(self.id) unless @ldp_object.present?
      yield @ldp_object
      return self
    end

    def attributes
      self.class.attribute_names.map do |name|
        [name.to_s, self.send(name)]
      end.to_h
    end

    def display_attributes
      self.class.display_attribute_names.map do |name|
        [name.to_s, self.send(name)]
      end
    end

    def inspect
      "#<#{self.class.to_s} id: #{self.id} " + self.class.attribute_names.map do |name|
        val = self.send(name)
        val_display = case 
        when val.is_a?(String)
          %Q|"#{val}"|
        when val.nil?
          'nil'
        when val.is_a?(Enumerable) && val.empty?
          '[]'
        else          
          val.to_s
        end
        "#{name}: #{val_display}"
      end.join(', ') + ">"
    end

    # TODO check if these are coming from activemodel

    # if we haven't had to load the internal ldp_object, by definition we must by synced to disk
    def persisted?
      return true unless ldp_object.present?
      return ldp_object.persisted?
    end

    def changed?
      return false unless ldp_object.present?
      return ldp_object.changed?
    end

    # errors forwarding?

    def valid?(*args)
      return super(*args) unless ldp_object.present?
      return ldp_object.valid?(*args)
    end

    def errors
      return super unless ldp_object.present?
      return ldp_object.errors
    end

    def self.new_locked_ldp_object(*attrs)
      new(ldp_obj: self.derived_af_class.new(*attrs))
    end

    # override this to control what attributes are automatically listed in the attributes list
    def self.display_attribute_names
      self.attribute_names - [:id]
    end

    # # Track attributes, so that we can avoid duplicating definitions in a separate indexer and on forms
    # def self.attribute_names
    #   @attribute_names
    # end

    def self.safe_attributes
      self.attribute_names - [:id]
    end

    def self.attribute_metadata(attribute_name)
      self.attribute_cache[attribute_name]
    end

    def self.solr_name_to_attribute_name(solr_name)
      self.reverse_solr_name_cache[solr_name]
    end

    def self.find(id)
      results_count, results, _ = perform_solr_query(%Q|_query_:"{!raw f=id}#{id}"|, '', false)
      raise ObjectNotFound, "Couldn't find #{self.to_s} with id='#{id}'" if results_count == 0
      raise MultipleIdViolationError if results_count > 1

      new(solr_doc: results.first)
    end

    def self.all
      results_count, results, _ = perform_solr_query('', '', false)
      results.map{|res| new_obj = new(solr_doc: res)}
    end

    def self.where(attributes)
      attr_queries = []
      attr_queries << attributes.map do |k, v| 
        solr_key = self.attribute_metadata(k)[:solr_names].first
        %Q|_query_:"{!field f=#{solr_key}}#{v}"|
      end

      results_count, results, _ = perform_solr_query(attr_queries, '', false)
      results.map{|res| new_obj = new(solr_doc: res)}
    end

    def self.search(q:'', fq:'')
      filter_queries = %W|has_model_ssim:"#{derived_af_class_name}"|
      filter_queries << fq

      results_count, results, facets = perform_solr_query(q || '', filter_queries, true, self.facets.map(&:to_s))

      return SearchResults.new(self, results_count, facets, results.map{|res| new(solr_doc: res)})
    end

    protected

    def self.perform_solr_query(q, fq, facet, facet_fields=[])
      query = []
      query << %Q|_query_:"{!raw f=has_model_ssim}#{derived_af_class_name}"|
      query.append(q) if q.present?

      response = ActiveFedora::SolrService.instance.conn.get("select", params: {q: query.join(' AND '),
        fq: fq,
        facet: facet,
        :'facet.field' => facet_fields
      })

      raise SearchFailed unless response['responseHeader']['status'] == 0

      return response['response']['numFound'], response['response']['docs'], response['facet_counts']
    end

    def initialize(solr_doc: nil, ldp_obj: nil)
      raise ArgumentError if solr_doc.present? && ldp_obj.present?
      self.solr_representation = solr_doc if solr_doc.present?
      self.ldp_object = ldp_obj if ldp_obj.present?
    end

    # clone inherited arrays/maps so that local mutation doesn't propogate to the parent
    def self.inherited(child)
      child.attribute_names = self.attribute_names.dup
      child.reverse_solr_name_cache = self.reverse_solr_name_cache.dup
      child.attribute_cache = self.attribute_cache.dup
      child.facets = self.facets.dup
      child.solr_calc_attributes = self.solr_calc_attributes.dup
    end

    def method_missing(name, *args, &block)
      if self.class.derived_af_class.instance_methods.include?(name)
        raise LockedInstanceError, "This is a locked cache instance and does not respond to the method you attempted to call (##{name}). However, the locked instance DOES respond to ##{name}. Use unlock_and_load_writable_ldp_object to load a writable copy (SLOW)."
      else
        super
      end
    end

    def ldp_object
      @ldp_object
    end

    def ldp_object=(obj)
      @ldp_object = obj
      @solr_representation = @ldp_object.to_solr
      @ldp_object.owning_object = self
      @ldp_object
    end

    def solr_representation=(doc)
      @solr_representation = doc
    end

    def self.ldp_object_includes(module_name)
      derived_af_class.send(:include, module_name)
    end

    def self.derived_af_class_name
      AF_CLASS_PREFIX + self.to_s
    end

    def self.unlocked(&block)
      derived_af_class.class_eval(&block)
    end

    # for a class Book, this would generate an ActiveFedora subclass "IRBook"
    def self.generate_af_class
      if !const_defined? derived_af_class_name
        self.af_parent_class ||= ActiveFedora::Base

        af_class = Class.new(self.af_parent_class) do
          attr_accessor :owning_object

          def owning_class
            self.class.owning_class
          end

          def self.owning_class
            @owning_class
          end

          # a single common indexer for all subclasses which leverages stored property metadata to DRY up indexing
          def self.indexer
            JupiterCore::Indexer
          end

          # RESPONDS TO MISSINGs

          def method_missing(name, *args, &block)
            if owning_object.respond_to?(name, true)
              owning_object.send(name, *args, &block)
            else
              super
            end
          end
        end
        af_class.instance_variable_set(:@owning_class, self)
        Object.const_set(derived_af_class_name, af_class)
        self.af_parent_class = af_class
        af_class
      else
        raise AlreadyDefinedError, "The attempted ActiveFedora class generation name '#{derived_af_class_name}' is already defined"
      end
    end

    def self.derived_af_class
      @derived_af_class ||= generate_af_class
    end

    def self.fetch_attribute_value(name)
      return ldp_object.send(name).freeze if ldp_object.present?
      val = solr_representation[solr_name_cache.first]
      return val.freeze if val.nil? || multiple
      return val.first.freeze
    end

    def self.solr_calculated_attribute(name, solrize_for:, &callable)
      raise PropertyInvalidError unless callable.respond_to?(:call)
      raise PropertyInvalidError unless name.present?
      raise PropertyInvalidError unless solrize_for.present? && solrize_for.is_a?(Symbol)

      self.solr_calc_attributes ||= {}
      self.solr_calc_attributes[name] = {type: SOLR_DESCRIPTOR_MAP[solrize_for], callable: callable}
    end

    # TODO name? Necessary?
    def self.has_multival_attribute(name, predicate, search_by_default: false, solrize_for: [], type: :string)
      self.has_attribute(name, predicate, multiple: true, search_by_default:search_by_default, solrize_for:solrize_for, type:type)
    end

    # a utility DSL for declaring attributes which allows us to store knowledge of them.
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

    def self.has_attribute(name, predicate, multiple: false, search_by_default: false, solrize_for: [], type: :string)
      raise PropertyInvalidError unless name.is_a? Symbol
      raise PropertyInvalidError unless predicate.present?
      
      # TODO keep this conveinience, or push responsibility for [] onto the callsite?
      solrize_for = [solrize_for] unless solrize_for.is_a? Array

      # index should contain only some combination of :search, :sort, :facet, :symbol, and :path
      # this isn't an exhaustive layering over this mess https://github.com/mbarnett/solrizer/blob/e5dd2bd571b9ebdb8a8ab214574075c28951e53e/lib/solrizer/default_descriptors.rb
      # but it helps
      raise PropertyInvalidError if (solrize_for.count {|item| !SOLR_DESCRIPTOR_MAP.keys.include?(item)} > 0)

      # TODO type validation

      self.attribute_names ||= [:id]
      self.attribute_cache ||= {}
      self.facets ||= []
      # @search_fields ||= []
      # @default_search_fields ||= []
      self.reverse_solr_name_cache ||= {}

      self.attribute_names << name

      solr_name_cache ||= []
      solrize_for.each do |descriptor| 
        solr_name = Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[descriptor], type: type)
        solr_name_cache << solr_name
        self.reverse_solr_name_cache[solr_name] = name
      end

      self.facets << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:facet], type: type) if solrize_for.include?(:facet)
      self.facets << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:path], type: type) if solrize_for.include?(:path)

      # searchable_fields = []
      # searchable_fields << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:search], type: type) if solrize_for.include?(:search)
      # searchable_fields << Solrizer.solr_name(name, SOLR_DESCRIPTOR_MAP[:symbol], type: type) if solrize_for.include?(:symbol)
    
      # @search_fields.concat(searchable_fields)
      # @default_search_fields.concat(searchable_fields) if search_by_default

      self.attribute_cache[name] = {
        predicate: predicate,
        multiple: multiple,
      #  search_by_default: search_by_default,
        solrize_for: solrize_for,
        type: type,
      #  search_fields: @search_fields,
      #  default_search_fields: @default_search_fields,
        solr_names: solr_name_cache
      }

      preferred_solr_name = solr_name_cache.first

      define_method name do
        return ldp_object.send(name).freeze if ldp_object.present? #&& ldp_object.changed?
        val = solr_representation[solr_name_cache.first]
        return val.freeze if val.nil? || multiple
        return val.first.freeze
      end

      define_method "#{name}=" do |*args|
        raise LockedInstanceError, "The Locked LDP object cannot be mutated outside of an unlocked block or without calling unlock_and_load_writable_ldp_object to load a writable copy (SLOW)."
      end

      derived_af_class.class_eval do
        property name, predicate: predicate, multiple: multiple do |index|
          index.type type if type.present?
          index.as *solrize_for.map {|index| SOLR_DESCRIPTOR_MAP[index]}
        end
      end
    end
  end
end