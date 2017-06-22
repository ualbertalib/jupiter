class JupiterCore::SearchResults
  attr_reader :count, :facet_names, :results

  def initialize(searched_class, count, facets, results)
    @count = count
    @facets = facets['facet_fields'].map do |k,v|
      {searched_class.solr_name_to_property_name(k) => v}
    end.reduce(:merge)

    @results = results

    @facet_names = @facets.keys
  end

  def each_facet_result_for(facet_name)
    @facets[facet_name].each_slice(2) do |name, count|
      yield name, count if name.present?
    end
  end
end