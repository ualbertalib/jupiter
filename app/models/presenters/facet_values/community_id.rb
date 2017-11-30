class Presenters::FacetValues::CommunityId < Presenters::FacetValues::DefaultPresenter
  def display
    Community.find(@value).title
  end
end
