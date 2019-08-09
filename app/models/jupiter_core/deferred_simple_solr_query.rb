class JupiterCore::DeferredSimpleSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods

  def initialize(klass)
    criteria[:model] = klass
    criteria[:limit] = JupiterCore::Search::MAX_RESULTS
    criteria[:sort] = []
    criteria[:sort_order] = []
    @children = []
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

  def order(attrs = {})
    ord = nil
    attr = if attrs.is_a? Hash
             a = attrs.keys.first
             ord = attrs[a]
             a
           else
             attrs
           end

    if attr.present?
      solr_name = begin
                    criteria[:model].solr_name_for(attr.to_sym, role: :sort)
                  rescue ArgumentError
                    nil
                  end
      criteria[:sort] = [solr_name] if solr_name.present?
    end
    criteria[:sort] = criteria[:model].default_sort_indexes if criteria[:sort].blank?
    criteria[:sort_order] = if ord.present? && [:asc, :desc].include?(ord.to_sym)
                              [ord]
                            else
                              criteria[:model].default_sort_direction
                            end
    self
  end

  # Composes a query object out of other, possibly heterogenous, query objects.
  # Only where clauses are preserved in the combined query. Sort orders, limits, and offsets must be re-specified
  # For sorts and where clauses on the combined query to be meaningful, the properties involved must share a name
  # and +solrize_for+ definition across all involved models. No attempt is made to enforce this, however.
  #
  # Examples:
  #
  # A single query returning all Items and all Theses:
  #
  #    Item.all + Thesis.all
  #
  # All items and theses belonging to a certain path:
  #
  #    Item.where(member_of_paths: path) + Thesis.where(member_of_paths: path)
  #
  # All items belonging to path 1 and all theses belonging to path 2:
  #
  #    Item.where(member_of_paths: path1) + Thesis.where(member_of_paths: path2)
  #
  # All items and theses belonging to a certain path, and a certain user:
  #
  #    (Item.where(member_of_paths: path) + Thesis.where(member_of_paths: path)).where(owner: user_id)
  #
  # A different way of retrieving all items and theses belonging to a certain path and user:
  #
  #    (Item.all + Thesis.all).where(member_of_paths: path).where(owner: user_id)
  #
  # A single query returning all items belonging to two different users:
  #
  #    Item.where(owner: user1.id) + Item.where(owner: user2.id)
  #
  # A single query returning all Theses owned by user1, and all public Items:
  #
  #    Item.public + Thesis.where(owner: user_id)
  #
  # A single query returning all Theses owned by user1, and all public Items where both Items and Theses are in a certain path
  #
  #    (Item.public + Thesis.where(owner: user_id)).where(member_of_paths: path)
  #
  # A single solr query returning a count of all Collections in a community, all Theses owned by user1, and all
  # public Items where both Items and Theses are in a certain path
  #
  #    (Collection.where(community_id: cid) + ((Item.public + Thesis.where(owner: user_id)).where(member_of_paths: path))).count
  #
  def +(other)
    combined_query = JupiterCore::DeferredSimpleSolrQuery.new(nil)
    combined_query.children.<< self
    combined_query.children << other

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
    results_count, _ = JupiterCore::Search.perform_solr_query(search_args_with_limit(0))
    results_count
  end

  # ActiveSupport#present? and other related protocols depend on this
  # semantically indicating the number of results from the query
  def empty?
    total_count == 0
  end

  def inspect_query
    JupiterCore::Search.prepare_solr_query(search_args_with_limit(criteria[:limit])).inspect
  end

  def used_sort_index
    criteria[:model].solr_name_to_attribute_name_map[criteria[:sort].first]
  end

  def used_sort_order
    criteria[:sort_order].first
  end

  private

  # Defer to Kaminari configuration in the +LockedLdpObject+ model
  def method_missing(method, *args, &block)
    if [:default_per_page, :max_per_page, :max_pages, :max_pages_per, :page].include? method
      model.send(method, *args, &block) if model.respond_to?(method)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    super || model.respond_to?(method, include_private)
  end

  def reified_result_set
    _, results, _ = JupiterCore::Search.perform_solr_query(search_args_with_limit(criteria[:limit]))
    results
  end

  def sort_clause
    indexes = criteria[:sort] || model.default_sort_indexes
    indexes ||= [model.solr_name_for(:record_created_at, role: :sort)]
    direction = criteria[:sort_order] || model.default_sort_direction
    direction ||= [:desc]

    sorts = []
    indexes.each_with_index do |sort_col, idx|
      sorts << "#{sort_col} #{direction[idx]}"
    end
    sorts.join(',')
  end

  protected

  attr_reader :children

  def model
    criteria[:model] || children.first.model
  end

  def where_clause
    query = []

    if criteria[:model].present?
      query << %Q(_query_:"{!raw f=has_model_ssim}#{criteria[:model].send(:derived_af_class).name}")
    end

    if children.present?
      child_queries = []
      children.each do |child|
        child_queries << "(#{child.where_clause})"
      end
      query << "(#{child_queries.join(' OR ')})"
    end

    if criteria[:where].present?
      common_attr_queries = []
      common_attr_queries << criteria[:where].map do |k, v|
        solr_key = k == :id ? k : model.attribute_metadata(k)[:solr_names].first
        %Q(#{solr_key}:"#{v}")
      end
      query << common_attr_queries.join(' AND ')
    end
    query.join(' AND ')
  end

  def search_args_with_limit(limit)
    { q: '',
      fq: where_clause,
      rows: limit,
      start: criteria[:offset],
      sort: sort_clause }
  end

end
