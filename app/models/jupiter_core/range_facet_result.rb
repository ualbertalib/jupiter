class JupiterCore::RangeFacetResult < JupiterCore::FacetResult

  attr_accessor :range
  alias_attribute :value, :range

  def initialize(facet_map, solr_index, range)
    super facet_map, solr_index
    @range = Range.new(range[:begin], range[:end])
  end

  def each_facet_value(_range = 0..-1)
    yield self
  end

end
