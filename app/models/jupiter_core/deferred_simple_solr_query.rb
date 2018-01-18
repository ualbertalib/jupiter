class JupiterCore::DeferredSimpleSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods

  def initialize(klass)
    klass = [klass] unless klass.is_a?(Array)
    criteria[:model] = klass
    criteria[:limit] = JupiterCore::Search::MAX_RESULTS
    criteria[:sort] = []
    criteria[:sort_order] = []
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
    criteria[:sort] << criteria[:model].first.solr_name_for(attr.to_sym, role: :sort)
    criteria[:sort_order] << order
    self
  end

  def +(other)
    combined_query = JupiterCore::DeferredSimpleSolrQuery.new([criteria[:model],
                                                               other.criteria[:model]].flatten)
    [criteria[:where], other.criteria[:where]].compact.each do |where_criteria|
      combined_query.where(where_criteria)
    end
    combined_query
  end

  # Enumerable support

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
    af_models = criteria[:model].map { |m| m.send(:derived_af_class) }
    results_count, _ = JupiterCore::Search.perform_solr_query(q: where_clause,
                                                              restrict_to_model: af_models,
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
      criteria[:model].first.send(method, *args, &block) if criteria[:model].first.respond_to?(method)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    super || criteria[:model].first.respond_to?(method, include_private)
  end

  def reified_result_set
    af_models = criteria[:model].map { |m| m.send(:derived_af_class) }
    _, results, _ = JupiterCore::Search.perform_solr_query(q: where_clause,
                                                           restrict_to_model: af_models,
                                                           rows: criteria[:limit],
                                                           start: criteria[:offset],
                                                           sort: sort_clause)
    results
  end

  def sort_clause
    sort(:record_created_at, :desc) if criteria[:sort].blank?
    sorts = []
    criteria[:sort].each_with_index do |sort_col, idx|
      sorts << "#{sort_col} #{criteria[:sort_order][idx]}"
    end
    sorts.join(',')
  end

  def where_clause
    if criteria[:where].present?
      attr_queries = []
      attr_queries << criteria[:where].map do |k, v|
        solr_key = k == :id ? k : criteria[:model].first.attribute_metadata(k)[:solr_names].first
        %Q(_query_:"#{solr_key}:#{v}")
      end
    else
      ''
    end
  end

end
