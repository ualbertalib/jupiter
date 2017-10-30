module SearchHelper
  def search_params_hash
    params.permit(:search, { facets: {} }, :tab, :sort, :direction).to_h
  end

  def query_params_with_facet(facet_name, value)
    query_params = search_params_hash
    query_params[:facets] ||= {}
    query_params[:facets][facet_name] = value
    query_params
  end

  def query_params_without_facet(facet_name)
    query_params = search_params_hash
    query_params[:facets]&.delete(facet_name)
    query_params.delete(:facets) if query_params[:facets]&.empty?

    query_params
  end

  def query_params_with_tab(tab)
    # Link for clicking a tab to switch models. Facets are stripped out
    query_params = search_params_hash.except(:facets)
    query_params[:tab] = tab

    query_params
  end

  def query_params_with_sort(sort, direction = 'asc')
    query_params = search_params_hash
    query_params[:sort] = sort
    query_params[:direction] = direction

    query_params
  end

  def results_model_tab_link(model)
    # Create bootstrap nav-item, make it a link if there are results for the model
    classes = 'nav-link'
    count = @results[model].total_count
    text = t("search.tab_header_#{model.to_s.pluralize}_with_count", count: count)
    if count == 0
      classes += ' disabled'
      inner_tag = content_tag(:span, text, class: classes)
    else
      classes += ' active' if @active_tab == model
      inner_tag = content_tag(:a, text, class: classes, href: search_path(query_params_with_tab(model)))
    end
    content_tag(:li, inner_tag, class: 'nav-item')
  end

  def sort_link(sort, direction)
    content_tag(:a, sort_label(sort, direction), class: 'dropdown-item',
                                                 href: search_path(query_params_with_sort(sort, direction)))
  end

  def sort_label(sort, direction)
    t("search.sort_#{sort}_#{direction}")
  end

  def results_range(results)
    first = results.offset_value + 1
    last = results.offset_value + results.count
    t('search.page_range', first: first, last: last, total: results.total_count)
  end
end
