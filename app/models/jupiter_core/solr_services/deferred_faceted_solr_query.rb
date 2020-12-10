class JupiterCore::SolrServices::DeferredFacetedSolrQuery

  include Enumerable
  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods::ClassMethods

  POSSIBLE_SORT_ORDERS = [:asc, :desc].freeze

  private_constant :POSSIBLE_SORT_ORDERS

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

  def sort(attributes, orders = nil)
    solr_exporter = raw_model_to_model(criteria[:restrict_to_model].first).solr_exporter_class
    # Assuming we are passing a list of attributes to sort by
    criteria[:sort] = []
    attributes = [attributes] unless attributes.is_a?(Array)
    orders = [orders] unless orders.is_a?(Array)

    criteria[:sort] = []
    criteria[:sort_order] = []

    attributes.each_with_index do |attr, idx|
      next if attr.blank?

      attr = attr.to_sym
      sort_attribute = begin
                        if attr == :relevance
                          # We change the sort attribute name because Solr uses score when sorting by relevance.
                          :score
                        else
                          solr_exporter.solr_name_for(attr, role: :sort)
                        end
                      rescue ArgumentError, JupiterCore::SolrServices::NameManglingError
                        nil
                      end

      # Ignore current sort attribute if we could not find its solr name. It is safe to ignore the pairing sort order
      next if sort_attribute.nil?

      criteria[:sort] << sort_attribute

      order = orders[idx]&.to_sym

      criteria[:sort_order] << if sort_attribute == :score
                                 # When sorting by score it only makes sense to use :desc order from the user
                                 # perspective so we ignore the order if one is given.
                                 :desc
                               elsif order.present? && POSSIBLE_SORT_ORDERS.include?(order)
                                 order
                               else
                                 # We could not find the order so we switch to default sort direction
                                 sort_direction_index = solr_exporter.default_sort_indexes.index(sort_attribute)
                                 solr_exporter.default_sort_direction[sort_direction_index]
                               end
    end

    # If no sort properties are set we resort to the default sort attributes
    if criteria[:sort].blank?
      criteria[:sort] = solr_exporter.default_sort_indexes
      criteria[:sort_order] = solr_exporter.default_sort_direction
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
        JupiterCore::SolrServices::RangeFacetResult.new(criteria[:facet_map], k, criteria[:ranges]
          .fetch(k,
                 begin: 1880,
                 end: Time.current.year).to_h)
      elsif v.present?
        JupiterCore::SolrServices::FacetResult.new(criteria[:facet_map], k, v)
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

  def raw_model_to_model(raw_model)
    raw_model
  end

end
