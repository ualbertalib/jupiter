class JupiterCore::SolrServices::DeferredSimpleSolrQuery

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

  def sort(attr, order = nil)
    solr_exporter = criteria[:model].solr_exporter_class
    if attr.present?
      solr_name = begin
                    solr_exporter.solr_name_for(attr.to_sym, role: :sort)
                  rescue ArgumentError
                    nil
                  end
      criteria[:sort] = [solr_name] if solr_name.present?
    end
    criteria[:sort] = solr_exporter.default_sort_indexes.first if criteria[:sort].blank?
    criteria[:sort_order] = if order.present? && [:asc, :desc].include?(order.to_sym)
                              [order]
                            else
                              solr_exporter.default_sort_direction[0]
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
    combined_query = JupiterCore::SolrServices::DeferredSimpleSolrQuery.new(nil)
    combined_query.children.<< self
    combined_query.children << other

    combined_query
  end

  # Enumerable support
  def each
    reified_result_set.map do |res|
      obj = begin
             # For the migration, ActiveRecord models had the prefix Ar, so that's what has_model_ssim
             # reflects in Solr. We've kept this post-migration to avoid the need to re-index, so for now
             # we remove the prefix when getting the model
             #
             # TODO: This is inefficient and we should look at batching up IDs
             arclass = res['has_model_ssim'].first.sub(/^Ar/, '').constantize
             arclass.with_eagerly_loaded_attachments.find(res['id'])
           rescue ActiveRecord::RecordNotFound
             # This _should_ only crop up in tests, where truncation of tables is bypassing callbacks that clean up
             # solr. BUT, I want to track this just in case.
             msg = "Removing a stale Solr result, #{res['id']}: #{res.inspect}"
             Rollbar.warning(msg)
             Rails.logger.warn(msg)
             JupiterCore::SolrServices::Client.instance.remove_document(res['id'])
             nil
           end
      yield obj if obj.present?
      obj
    end.flatten
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
    solr_exporter = criteria[:model].solr_exporter_class
    solr_exporter.name_for_mangled_name([criteria[:sort].first])
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
    _, results, _, _ = JupiterCore::Search.perform_solr_query(search_args_with_limit(criteria[:limit]))
    results
  end

  def sort_clause
    solr_exporter = model.solr_exporter_class
    indexes = criteria[:sort] || solr_exporter.default_sort_indexes.first
    indexes ||= [solr_exporter.solr_name_for(:record_created_at, role: :sort)]
    direction = criteria[:sort_order] || solr_exporter.default_sort_direction[0]
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
    solr_exporter = model.solr_exporter_class
    fquery = []
    idquery = ''

    fquery << %Q(_query_:"{!raw f=has_model_ssim}#{solr_exporter.indexed_has_model_name}") if criteria[:model].present?

    if children.present?
      child_queries = []
      children.each do |child|
        # HACK: note that we just drop child query q: queries, which are just for ID, because the id support is a bit
        # of a hack at the moment
        child_queries << "(#{child.where_clause[:fq]})"
      end
      fquery << "(#{child_queries.join(' OR ')})"
    end

    if criteria[:where].present?
      common_attr_queries = []
      where = criteria[:where].select {|k,v| k != :id}
      common_attr_queries << where.map do |k, v|
        case k
        when :updated_on_or_after
          "updated_at_dtsi:[#{v} TO NOW]"
        when :updated_before
          "updated_at_dtsi:[* TO #{v}}"
        when :member_of_paths
          %Q(member_of_paths_ngrams:"#{v}")
        else
          solr_key = solr_exporter.solr_names_for(k).first
          %Q(#{solr_key}:"#{v}")
        end
      end
      fquery << common_attr_queries.join(' AND ')
      idquery = %Q({!term f=id}#{criteria[:where][:id]}) if criteria[:where].key?(:id)
    end
    {
      q: idquery,
      fq: fquery.reject(&:empty?).join(' AND ')
    }
  end

  def search_args_with_limit(limit)
    query = where_clause

    { q: query[:q],
      fq: query[:fq],
      rows: limit,
      start: criteria[:offset],
      sort: sort_clause }
  end

end
