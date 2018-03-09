class JupiterCore::RangeResult

  attr_accessor :category_name, :attribute_name, :min, :max, :missing, :solr_index

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

    # values are a hash of statisics => values
    # "min", "max", "count", "missing", "sum", "sumOfSquares", "mean", "stddev"
    # https://lucene.apache.org/solr/guide/6_6/the-stats-component.html
    self.min = values['min'].to_i
    self.max = values['max'].to_i
    self.missing = values['missing'].to_i
  end

end
