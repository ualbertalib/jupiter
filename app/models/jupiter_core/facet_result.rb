class JupiterCore::FacetResult

  attr_accessor :name, :values, :presenter, :facet_name

  def initialize(facet_map, facet_name, values, presenter: nil)
    self.facet_name = facet_name

    # Allows the user to override the presentation name for the facet category by customizing the
    # facets.<attribute_name> in the locale file.
    self.name = if I18n.exists?("facets.#{facet_map[facet_name]}")
                  I18n.t("facets.#{facet_map[facet_name]}")
                else
                  facet_map[facet_name].to_s.titleize
                end

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

  def count
    @values.count
  end

  def each_facet_value(*range_args)
    # When many facets are iterated, we need to segregate into ranges based on what is shown or not
    range = if range_args.present?
              range_args
            else
              [0..-1]
            end
    keys = @values.keys.slice(*range)
    keys.each do |raw_value|
      count = @values[raw_value]
      if raw_value.present?
        presentable_value = presenter.call(raw_value)
        yield presentable_value, raw_value, count
      end
    end
  end

end
