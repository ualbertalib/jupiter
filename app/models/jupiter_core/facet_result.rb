class JupiterCore::FacetResult

  attr_accessor :category_name, :attribute_name, :solr_index

  def initialize(facet_map, solr_index)
    self.solr_index = solr_index
    self.attribute_name = facet_map[solr_index]

    # Allows the user to override the presentation name for the facet category by customizing the
    # facets.<attribute_name> in the locale file.
    self.category_name = if I18n.exists?("facets.#{attribute_name}")
                           I18n.t("facets.#{attribute_name}")
                         else
                           attribute_name.to_s.titleize
                         end
  end

  # When many facets are iterated, we need to segregate into ranges based on what is shown or not
  def each_facet_value(_range = 0..-1)
    [] # child class should implent, this is here so UI doesn't break
  end

end
