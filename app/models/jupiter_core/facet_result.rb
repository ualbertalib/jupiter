class JupiterCore::FacetResult

  attr_accessor :name

  def initialize(searched_class, name, values)
    self.name = searched_class.solr_name_to_attribute_name(name).to_s.titleize

    # values are just a key => value hash of facet text to count
    # we have to filter out all of the useless "" facets Solr sends back for non-required fields
    @values = values.each_slice(2).map do |name, count|
      name.present? ? {name => count} : {}
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