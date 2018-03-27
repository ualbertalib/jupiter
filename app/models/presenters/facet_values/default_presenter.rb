class Presenters::FacetValues::DefaultPresenter

  attr_reader :count

  def initialize(view, active_facets, facet_value)
    @value = facet_value.value
    @count = facet_value.count
    @solr_index = facet_value.solr_index
    @active_facets = active_facets || {}
    @view = view
  end

  def facet_search_link
    # TODO: can we move this to the view?
    if @active_facets[@solr_index].present? && @active_facets[@solr_index].include?(@value)
      @view.link_to @view.query_params_without_facet_value(@solr_index, @value), rel: 'nofollow' do
        @view.concat(@view.content_tag(:span, @count, class: 'ml-2 badge badge-light pull-right'))
        @view.concat(@view.fa_icon('check-square-o', class: 'mr-2'))
        @view.concat(display)
      end
    else
      @view.link_to @view.query_params_with_facet(@solr_index, @value), rel: 'nofollow' do
        @view.concat(@view.content_tag(:span, @count, class: 'ml-2 badge badge-light pull-right'))
        @view.concat(@view.fa_icon('square-o', class: 'mr-2'))
        @view.concat(display)
      end
    end
  end

  def display
    @value
  end

end
