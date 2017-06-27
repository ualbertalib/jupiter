class JupiterCore::SearchResults
  attr_reader :count, :facet_names, :results

  def initialize(searched_class, count, facets, results)
    @count = count
    @facets = facets['facet_fields'].map do |k, v|
      JupiterCore::FacetResult.new(searched_class, k, v)
    end

    @results = results
  end

  def each_facet_with_results
    @facets.each do |facet|
      yield facet if facet.present?
    end
  end
end