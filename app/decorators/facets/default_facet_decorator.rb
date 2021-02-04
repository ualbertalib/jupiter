class Facets::DefaultFacetDecorator

  attr_reader :count

  def initialize(view, active_facets, facet_value)
    @value = facet_value.value
    @category_name = facet_value.short_category_name
    @count = facet_value.count
    @solr_index = facet_value.solr_index
    @active_facets = active_facets || {}
    @view = view
  end

  def facet_search_link
    # TODO: can we move this to the view?
    if @active_facets[@solr_index].present? && @active_facets[@solr_index].include?(@value)
      @view.link_to @view.query_params_without_facet_value(@solr_index, @value), rel: 'nofollow' do
        @view.concat(@view.tag.span(@count, class: 'ml-2 badge badge-light float-right'))
        @view.concat(@view.icon('far', 'check-square', class: 'mr-2'))
        @view.concat(display_value)
      end
    else
      @view.link_to @view.query_params_with_facet(@solr_index, @value), rel: 'nofollow' do
        @view.concat(@view.tag.span(@count, class: 'ml-2 badge badge-light float-right'))
        @view.concat(@view.icon('far', 'square', class: 'mr-2'))
        @view.concat(display_value)
      end
    end
  end

  def display
    if Flipper.enabled?(:facet_badge_category_name)
      "#{@category_name}: #{display_value}"
    else
      display_value
    end
  end

  def display_value
    @value
  end

end
