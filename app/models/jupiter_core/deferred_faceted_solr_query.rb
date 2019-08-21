# TODO: There's enough overlap that we could look at combining this with DeferredSimpleSolrQuery although
# the wide difference in what we need to pass in and get out of the two different kinds of uses of Solr, particularly
# wrt the need for this to support results mixing multiple models, may make that trickier than just living with the
# similarities. Also, DeferredSimpleSolrQuery probably goes away if we move to ActiveRecord, as it's mostly just an
# AR-finder simulation layer of low value
class JupiterCore::DeferredFacetedSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods::ClassMethods

  def initialize(q:, qf:, fq:, facet_map:, facet_fields:, ranges:, restrict_to_model:)
    criteria[:q] = q
    criteria[:qf] = qf # Query Fields
    criteria[:fq] = fq # Facet Query
    criteria[:facet_map] = facet_map
    criteria[:facet_fields] = facet_fields
    criteria[:ranges] = ranges
    criteria[:restrict_to_model] = restrict_to_model
    criteria[:sort] = []
    criteria[:sort_order] = []
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

  def sort(attr, order = nil)
    solr_exporter = raw_model_to_model(criteria[:restrict_to_model].first).solr_exporter_class

    if attr.present?
      attr = attr.to_sym
      solr_name = begin
                    if attr == :relevance
                      :score
                    else
                      solr_exporter.solr_name_for(attr, role: :sort)
                    end
                  rescue ArgumentError
                    nil
                  end
      criteria[:sort] = [solr_name] if solr_name.present?
    end
    criteria[:sort] = solr_exporter.default_sort_indexes if criteria[:sort].blank?

    # Note the elsif: if no explicit order was passed from the user, and we're ordering by score, we default
    # to sorting scores descending rather than ascending, as is otherwise used when eg) title is the default sort field
    criteria[:sort_order] = if order.present? && [:asc, :desc].include?(order.to_sym)
                              [order]
                            elsif criteria[:sort] == [:score]
                              [:desc]
                            else
                              solr_exporter.default_sort_direction
                            end
    self
  end

  def facet_results_present?
    reify_result_set
    @facets.present?
  end

  def each_facet_with_results(first_facet_categories = [])
    reify_result_set
    # first_categories indicates which facets should be treated first (for example, selected facets in a query)
    # Order in first_categories matters
    facets = @facets.sort_by do |facet|
      idx = first_facet_categories.find_index(facet.solr_index)
      idx ||= first_facet_categories.length + 1
      idx
    end
    facets.each do |facet|
      yield facet if facet.present?
    end
  end

  def each
    reify_result_set.map do |res|
      obj = if res['has_model_ssim'].first.start_with?('IR')
              JupiterCore::LockedLdpObject.reify_solr_doc(res)
            else
              # TODO: This is inefficient and we should look at batching up IDs once Fedora is gone and I can change this a bit
              arclass = res['has_model_ssim'].first.sub(/^Ar/, '').constantize
              arclass.find(res['id'])
            end
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
    @total_count_cache ||= begin
      results_count, _ = JupiterCore::Search.perform_solr_query(search_args_with_limit(0))
      results_count
    end
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
    return :relevance if criteria[:sort].first == :score

    model = raw_model_to_model(criteria[:restrict_to_model].first)
    model.solr_exporter_class.reverse_solr_name_map[criteria[:sort].first]
  end

  def used_sort_order
    criteria[:sort_order].first
  end

  private

  def uncache!
    @count_cache = @total_count_cache = nil
  end

  def reify_result_set
    return @results if @results.present?

    model = raw_model_to_model(criteria[:restrict_to_model].first)
    # TODO: refactor special treatment of this attribute name to be more generically applicable to any range facet
    model_has_sort_year = model.solr_exporter_class.indexed_attributes.include?(:sort_year)
    sort_year_facet = model.solr_exporter_class.solr_name_for(:sort_year, role: :range_facet) if model_has_sort_year

    @count_cache, @results, facet_data = JupiterCore::Search.perform_solr_query(
      search_args_with_limit(criteria[:limit])
    )

    @facets = facet_data['facet_fields'].map do |k, v|
      if model_has_sort_year && (k == sort_year_facet)
        JupiterCore::RangeFacetResult.new(criteria[:facet_map], k, criteria[:ranges].fetch(k,
                                                                                           begin: 1880,
                                                                                           end: Time.current.year).to_h)
      elsif v.present?
        JupiterCore::FacetResult.new(criteria[:facet_map], k, v)
      end
    end.compact

    @results
  end

  def sort_clause
    model = raw_model_to_model(criteria[:restrict_to_model].first)
    solr_exporter = model.solr_exporter_class
    indexes = criteria[:sort].presence || solr_exporter.default_sort_indexes
    indexes ||= [solr_exporter.solr_name_for(:record_created_at, role: :sort)]
    direction = criteria[:sort_order].presence || solr_exporter.default_sort_direction
    direction ||= [:desc]

    sorts = []
    indexes.each_with_index do |sort_col, idx|
      sorts << "#{sort_col} #{direction[idx]}"
    end
    sorts.join(',')
  end

  def search_args_with_limit(limit)
    { q: criteria[:q],
      qf: criteria[:qf],
      fq: criteria[:fq],
      facet: true,
      facet_fields: criteria[:facet_fields],
      restrict_to_model: criteria[:restrict_to_model],
      rows: limit,
      start: criteria[:offset],
      sort: sort_clause }
  end

  # Convert IRModel to corresponding LockedLDPObject class or justt pass through ActiveRecord class
  def raw_model_to_model(raw_model)
    if raw_model < ActiveFedora::Base
      raw_model.owning_class
    else
      raw_model
    end
  end

end
