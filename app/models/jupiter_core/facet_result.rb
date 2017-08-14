class JupiterCore::FacetResult

  attr_accessor :name, :values

  def initialize(facet_map, name, values)
    self.name = facet_map[name].to_s.titleize

    # values are just a key => value hash of facet text to count
    # we have to filter out all of the useless "" facets Solr sends back for non-required fields
    @values = values.each_slice(2).map do |value_name, count|
      value_name.present? ? { value_name => count } : {}
    end.reduce(:merge)
  end

  def present?
    @values.keys.present?
  end

  def each_facet_value
    @values.each do |name, count|
      yield name, count if name.present?
    end
  end

end
