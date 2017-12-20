module ItemsHelper
  def item_type_search_link(item)
    search_link_for(item, :item_type_with_status,
                    value: item.item_type_with_status_code,
                    display: humanize_uri_code(:item_type_with_status, item.item_type_with_status_code))
  end

  def language_search_link(item, language_uri)
    search_link_for(item, :languages, value: language_uri,
                                      display: humanize_uri(:language, language_uri))
  end
end
