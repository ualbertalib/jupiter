class Facets::ItemTypeWithStatus < Facets::DefaultFacetDecorator

  def display_value
    I18n.t("controlled_vocabularies.era.item_type_with_status.#{@value}")
  end

end
