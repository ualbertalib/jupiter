class Presenters::FacetValues::ItemTypeWithStatus < Presenters::FacetValues::DefaultPresenter

  def display
    I18n.t("controlled_vocabularies.item_type_with_status.#{@value}")
  end

end
