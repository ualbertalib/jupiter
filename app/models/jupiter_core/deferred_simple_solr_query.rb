class JupiterCore::DeferredSimpleSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods

  def initialize(klass)
    criteria[:model] = klass
    criteria[:limit] = JupiterCore::Search::MAX_RESULTS
    sort(:record_created_at, :desc)
  end

  def criteria
    @criteria ||= {}
  end

  def where(attributes)
    criteria[:where] ||= {}
    criteria[:where].merge!(attributes)
    self
  end

  def limit(num)
    criteria[:limit] = num
    self
  end

  def offset(num)
    criteria[:offset] = num
    self
  end

  def sort(attr, order = :desc)
    raise ArgumentError, 'order must be :asc or :desc' unless [:asc, :desc].include?(order.to_sym)
    criteria[:sort] = criteria[:model].solr_name_for(attr.to_sym, role: :sort)
    criteria[:sort_order] = order
    self
  end

  def each
    reified_result_set.map do |res|
      obj = JupiterCore::LockedLdpObject.reify_solr_doc(res)
      yield(obj)
      obj
    end
  end

  # Kaminari integration

  def offset_value
    criteria[:offset]
  end

  def limit_value
    criteria[:limit]
  end

  # Kaminari integration
  define_method Kaminari.config.page_method_name, (proc { |num|
    limit(default_per_page).offset(default_per_page * ([num.to_i, 1].max - 1))
  })

  def total_count
    af_model = criteria[:model].send(:derived_af_class)
    results_count, _ = JupiterCore::Search.perform_solr_query(q: where_clause,
                                                              restrict_to_model: af_model,
                                                              rows: 0,
                                                              start: criteria[:offset],
                                                              sort: sort_clause)
    results_count
  end

  # ActiveSupport#present? and other related protocols depend on this
  # semantically indicating the number of results from the query
  def empty?
    total_count == 0
  end

  private

  # Defer to Kaminari configuration in the +LockedLdpObject+ model
  def method_missing(method, *args, &block)
    if [:default_per_page, :max_per_page, :max_pages, :max_pages_per, :page].include? method
      criteria[:model].send(method, *args, &block) if criteria[:model].respond_to?(method)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    super || criteria[:model].respond_to?(method, include_private)
  end

  def reified_result_set
    _, results, _ = JupiterCore::Search.perform_solr_query(q: where_clause,
                                                           restrict_to_model: criteria[:model].send(:derived_af_class),
                                                           rows: criteria[:limit],
                                                           start: criteria[:offset],
                                                           sort: sort_clause)
    results
  end

  def sort_clause
    "#{criteria[:sort]} #{criteria[:sort_order]}"
  end

  def where_clause
    if criteria[:where].present?
      attr_queries = []
      attr_queries << criteria[:where].map do |k, v|
        solr_key = k == :id ? k : criteria[:model].attribute_metadata(k)[:solr_names].first
        %Q(_query_:"{!field f=#{solr_key}}#{v}")
      end
    else
      ''
    end
  end

end
