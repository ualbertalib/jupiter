module ApplicationHelper
  def page_title(title)
    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end

  def link_for_facet(facet_name, value)
    query = params[:q]
    active_facets = params[:facets] if params[:facets]
    if active_facets[facet_name].present?
      active_facets[facet_name] << value
    else
      active_facets[facet_name] = [value]
    end


  end
end
