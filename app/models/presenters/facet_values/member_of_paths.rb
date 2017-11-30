class Presenters::FacetValues::MemberOfPaths < Presenters::FacetValues::DefaultPresenter
  def display
    Item.path_to_titles(@value)
  end
end
