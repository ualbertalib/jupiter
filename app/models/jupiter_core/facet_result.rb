class JupiterCore::FacetResult

  attr_accessor :name, :values, :presenter

  def initialize(facet_map, name, values, presenter:nil)
    self.name = facet_map[name].to_s.titleize

    self.presenter = presenter || ->(value) {value}
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
      if name.present?
        presentable_name = self.presenter.call(name)
        yield presentable_name, count
      end
    end
  end

end
