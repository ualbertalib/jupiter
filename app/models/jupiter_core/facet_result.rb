class JupiterCore::FacetResult

  attr_accessor :name, :values, :presenter, :facet_name

  def initialize(facet_map, facet_name, values, presenter: nil)
    self.facet_name = facet_name
    self.name = facet_map[facet_name].to_s.titleize

    # Either a property specified a custom presenter in its has_property definition,
    # or we supply a default that simply displays the value as it appears in Solr
    self.presenter = presenter || ->(value) { value }

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
    @values.each do |raw_value, count|
      if raw_value.present?
        presentable_value = presenter.call(raw_value)
        yield presentable_value, raw_value, count
      end
    end
  end

end
