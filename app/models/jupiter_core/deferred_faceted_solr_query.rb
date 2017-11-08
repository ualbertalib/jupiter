# TODO: There's enough overlap that we could look at combining this with DeferredSimpleSolrQuery although
# the wide difference in what we need to pass in and get out of the two different kinds of uses of Solr, particularly
# wrt the need for this to support results mixing multiple models, may make that trickier than just living with the
# similarities. Also, DeferredSimpleSolrQuery probably goes away if we move to ActiveRecord, as it's mostly just an
# AR-finder simulation layer of low value
class JupiterCore::DeferredFacetedSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods::ClassMethods

  def initialize(q:, qf:, fq:, facet_map:, facet_fields:, facet_value_presenters:, restrict_to_model:)
    criteria[:q] = q
    criteria[:qf] = qf
    criteria[:fq] = fq
    criteria[:facet_map] = facet_map
    criteria[:facet_fields] = facet_fields
    criteria[:restrict_to_model] = restrict_to_model
    criteria[:facet_value_presenters] = facet_value_presenters
    sort(:record_created_at, :desc)
  end

  def criteria
    @criteria ||= {}
  end

  def limit(num)
    uncache!
    criteria[:limit] = num
    self
  end

  def offset(num)
    uncache!
    criteria[:offset] = num
    self
  end

  def sort(attr, order = :desc)
    raise ArgumentError, 'order must be :asc or :desc' unless [:asc, :desc].include?(order.to_sym)

    # Right now we're just going to look this up on the first model, but for this to make sense,
    # as something results can be sorted by, all models should have the same attribute name, solrized_for_sorting
    metadata = criteria[:restrict_to_model].first.owning_class.attribute_metadata(attr.to_sym)
    raise ArgumentError, "No metadata found for attribute #{attr}" if metadata.blank?

    sort_attr_index = metadata[:solrize_for].index(:sort)
    raise ArgumentError, "The given attribute, #{attr}, is not solrized for sorting" if sort_attr_index.blank?

    criteria[:sort] = metadata[:solr_names][sort_attr_index]
    criteria[:sort_order] = order
    self
  end

  def each_facet_with_results
    @facets.each do |facet|
      yield facet if facet.present?
    end
  end

  def each
    reify_result_set.map do |res|
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

  def count
    @count_cache ||= super
  end

  def total_count
    results_count, _ = JupiterCore::Search.perform_solr_query(q: criteria[:q],
                                                              qf: criteria[:qf],
                                                              fq: criteria[:fq],
                                                              restrict_to_model: criteria[:restrict_to_model],
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

  def uncache!
    @count_cache = nil
  end

  def reify_result_set
    return @results if @results.present?
    _, @results, facet_data = JupiterCore::Search.perform_solr_query(q: criteria[:q],
                                                                     qf: criteria[:qf],
                                                                     fq: criteria[:fq],
                                                                     facet: true,
                                                                     facet_fields: criteria[:facet_fields],
                                                                     restrict_to_model: criteria[:restrict_to_model],
                                                                     rows: criteria[:limit],
                                                                     start: criteria[:offset],
                                                                     sort: sort_clause)

    @facets = facet_data['facet_fields'].map do |k, v|
      presenter = criteria[:facet_value_presenters][k]
      JupiterCore::FacetResult.new(criteria[:facet_map], k, v, presenter: presenter) if v.present?
    end.compact

    @results
  end

  def sort_clause
    "#{criteria[:sort]} #{criteria[:sort_order]}"
  end

end
