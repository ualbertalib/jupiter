class JupiterCore::FieldValueFacetResult < JupiterCore::FacetResult

  FacetValue = Struct.new(:attribute_name, :solr_index, :value, :count)

  attr_accessor :category_name, :attribute_name, :values, :solr_index

  def initialize(facet_map, solr_index, values)
    super facet_map, solr_index

    # values are just a key => value hash of facet text to count
    # we have to filter out all of the useless "" facets Solr sends back for non-required fields
    @values = values.each_slice(2).map do |value_name, count|
      value_name.present? ? { value_name => count } : {}
    end.reduce(:merge)
  end

  def present?
    @values.keys.present?
  end

  def count
    @values.count
  end

  # When many facets are iterated, we need to segregate into ranges based on what is shown or not
  def each_facet_value(range = 0..-1)
    keys = @values.keys.slice(range)
    keys.each do |raw_value|
      count = @values[raw_value]
      if raw_value.present?
        yield FacetValue.new(attribute_name, solr_index, raw_value, count)
      end
    end
  end

end
