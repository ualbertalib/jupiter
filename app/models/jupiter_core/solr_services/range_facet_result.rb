class JupiterCore::SolrServices::RangeFacetResult

  attr_reader :solr_index, :category_name, :short_category_name, :range

  def initialize(facet_map, solr_index, range)
    @solr_index = solr_index
    attribute_name = facet_map[solr_index]

    # Allows the user to override the presentation name for the facet category by customizing the
    # facets.<attribute_name> in the locale file.
    @category_name = I18n.t("facets.#{attribute_name}", default: attribute_name.to_s.titleize)
    @short_category_name = I18n.t("facets.short.#{attribute_name}", default: @category_name)

    @range = Range.new(range[:begin], range[:end])
  end

  def value
    @range.to_s.gsub('..', ' to ')
  end

  def to_partial_path
    'range_facet_result'
  end

  def count; end

end
