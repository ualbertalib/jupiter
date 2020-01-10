class JupiterCore::SolrServices::FacetResult

  FacetValue = Struct.new(:attribute_name, :solr_index, :value, :count)

  attr_accessor :category_name, :attribute_name, :values, :solr_index

  def initialize(facet_map, solr_index, values)
    self.solr_index = solr_index
    self.attribute_name = facet_map[solr_index]

    # Allows the user to override the presentation name for the facet category by customizing the
    # facets.<attribute_name> in the locale file.
    self.category_name = if I18n.exists?("facets.#{attribute_name}")
                           I18n.t("facets.#{attribute_name}")
                         else
                           attribute_name.to_s.titleize
                         end

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
      yield FacetValue.new(attribute_name, solr_index, raw_value, count) if raw_value.present?
    end
  end

  def to_partial_path
    'facet_result'
  end

end
