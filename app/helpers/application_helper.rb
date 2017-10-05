module ApplicationHelper
  def page_title(title)
    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end

  def facetable_query_params(facet_name, value)
    query_params = {q: params[:q]}
    active_facets = params[:facets] if params[:facets]
    active_facets ||= {}
    active_facets[facet_name] = value
    query_params[:facets] = active_facets

    query_params
  end
end
