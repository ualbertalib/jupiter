module SearchHelper
  def search_params_hash
    params.permit(:search, { facets: {} }, { ranges: {} }, :tab, :sort, :direction, :community_id, :id, :page, :utf8)
          .to_h.except(:page, :utf8)
  end

  def active_facet?(facet_value)
    params[:facets]&.fetch(facet_value.solr_index, [])&.include?(facet_value.value)
  end

  def active_range?(range_facet_result)
    params[:ranges]&.fetch(range_facet_result.solr_index, false)
  end

  # Rubocop now wants us to remove instance methods from helpers. This is a good idea
  # but will require a bit of refactoring. Find other instances of this disabling
  # and fix all at once.
  def facet_display_order
    priority_facets = (params[:facets]&.keys || []) + (params[:ranges]&.keys || [])
    return priority_facets unless search_models.include? Item

    priority_facets + [Item.solr_exporter_class.solr_name_for(:all_contributors, role: :facet),
                       Item.solr_exporter_class.solr_name_for(:all_subjects, role: :facet)]
  end

  def enable_item_sort?
    search_models.include? Item
  end

  def query_params_with_facet(facet_name, value)
    query_params = search_params_hash
    query_params[:facets] ||= {}
    query_params[:facets][facet_name] ||= []
    query_params[:facets][facet_name] << value
    query_params
  end

  def query_params_without_facet_value(facet_name, value)
    query_params = search_params_hash
    raise ArgumentError, 'No facets are present' unless query_params.key?(:facets)
    raise ArgumentError, 'No query param is present for this facet' unless query_params[:facets].key?(facet_name)

    query_params[:facets][facet_name].delete(value)
    query_params[:facets].delete(facet_name) if query_params[:facets][facet_name].empty?
    query_params.delete(:facets) if query_params[:facets].empty?

    query_params
  end

  def query_params_without_range_value(facet_name)
    query_params = search_params_hash
    raise ArgumentError, 'No ranges are present' unless query_params.key?(:ranges)
    raise ArgumentError, 'No query param is present for this range' unless query_params[:ranges].key?(facet_name)

    query_params[:ranges].delete(facet_name)
    query_params.delete(:ranges) if query_params[:ranges].empty?

    query_params
  end

  def query_params_with_tab(tab)
    # Link for clicking a tab to switch models. Facets are stripped out
    query_params = search_params_hash.except(:facets, :ranges)
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
    name = model.name.downcase.to_sym
    if search_models.include? model
      count = results.total_count
      text = content_tag(:h2, t("search.tab_header_#{name}_with_count", count: count), class: 'h5')
      classes += ' active'
    else
      text = content_tag(:h2, t("search.tab_header_#{name}"), class: 'h5')
    end
    content_tag(:li, content_tag(:a, text, class: classes, href: search_path(query_params_with_tab(name))),
                class: 'nav-item')
  end

  def search_sort_link(sort, direction)
    link_to search_sort_label(sort, direction), query_params_with_sort(sort, direction),
            class: 'dropdown-item', rel: 'nofollow'
  end

  def search_sort_label(sort, direction)
    t("search.sort_#{sort}_#{direction}")
  end

  def search_sort_label_for_relation(relation)
    direction = relation.arel.orders.first.direction
    sort = relation.arel.orders.first.value.name
    search_sort_label(sort, direction)
  end

  def results_range(results)
    first = results.offset_value + 1
    last = results.offset_value + results.count
    t('search.page_range', first: first, last: last, total: results.total_count)
  end
end
