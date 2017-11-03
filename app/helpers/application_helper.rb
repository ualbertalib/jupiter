module ApplicationHelper
  def page_title(title)
    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end

  def path_for_result(result)
    if result.is_a? Collection
      community_collection_path(result.community, result)
    else
      polymorphic_path(result)
    end
  end

  def facetable_query_params(facet_name, value)
    query_params = { search: params[:search] }
    active_facets = params[:facets] || {}
    active_facets[facet_name] = value
    query_params[:facets] = active_facets

    query_params
  end

  def help_tooltip(text)
    content_tag(:span, fa_icon('question-circle'), title: text)
  end

  def results_range(results)
    # results come from a Jupiter query/search with pagination
    first = results.offset_value + 1
    last = results.offset_value + results.count
    t(:page_range, first: first, last: last, total: results.total_count)
  end
end
