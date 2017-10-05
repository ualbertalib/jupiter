class JupiterCore::SearchResults

  include Enumerable
  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods

  def initialize(q:, fq:, facet_map:,facet_fields:, facet_value_presenters:, restrict_to_model:)
    criteria[:q] = q
    criteria[:fq] = fq
    criteria[:facet_map] = facet_map
    criteria[:facet_fields] = facet_fields
    criteria[:restrict_to_model] = restrict_to_model
    criteria[:facet_value_presenters] = facet_value_presenters
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

  def count
    @count_cache ||= super
  end

  def total_count
    results_count, _ = JupiterCore::Search.perform_solr_query(q: criteria[:q],
                                                              fq: criteria[:fq],
                                                              restrict_to_model: criteria[:restrict_to_model],
                                                              rows: 0,
                                                              start: criteria[:offset])
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
                                                                  fq: criteria[:fq],
                                                                  facet: true,
                                                                  facet_fields: criteria[:facet_fields],
                                                                  restrict_to_model: criteria[:restrict_to_model],
                                                                  rows: criteria[:limit],
                                                                  start: criteria[:offset])

    @facets = facet_data['facet_fields'].map do |k, v|
      presenter = criteria[:facet_value_presenters][k]
      JupiterCore::FacetResult.new(criteria[:facet_map], k, v, presenter: presenter) if v.present?
    end.compact

    @results
  end

end
