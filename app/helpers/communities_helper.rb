module CommunitiesHelper
  def communities_collections_sort_label(sort, direction)
    t("communities.sort_#{sort}_#{direction}")
  end

  def communities_collections_sort_link(sort, direction)
    # Link for current path with appropriate label and sort params
    link_to communities_collections_sort_label(sort, direction), { sort: sort, direction: direction },
            class: 'dropdown-item'
  end
end
