class JupiterCore::SearchResults

  attr_reader :count, :results

  def initialize(facet_map, count, facets, results)
    @count = count
    @facets = facets['facet_fields'].map do |k, v|
      JupiterCore::FacetResult.new(facet_map, k, v)
    end

    @results = results
  end

  def each_facet_with_results
    @facets.each do |facet|
      yield facet if facet.present?
    end
  end

end
