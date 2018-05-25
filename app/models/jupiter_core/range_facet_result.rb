class JupiterCore::RangeFacetResult

  attr_reader :solr_index, :category_name, :range

  def initialize(facet_map, solr_index, range)
    @solr_index = solr_index
    attribute_name = facet_map[solr_index]

    # Allows the user to override the presentation name for the facet category by customizing the
    # facets.<attribute_name> in the locale file.
    @category_name = if I18n.exists?("facets.#{attribute_name}")
                       I18n.t("facets.#{attribute_name}")
                     else
                       attribute_name.to_s.titleize
                     end

    @range = Range.new(range[:begin], range[:end])
  end

  def humanized_range
    @range.to_s.gsub('..', ' to ')
  end

  def to_partial_path
    'range_facet_result'
  end

end
