module ItemsHelper
  def item_type_search_link(item)
    search_link_for(item, :item_type_with_status,
                    value: item.item_type_with_status_code,
                    display: t("controlled_vocabularies.item_type_with_status.#{item.item_type_with_status_code}"))
  end

  def language_search_link(item, language_uri)
    search_link_for(item, :languages, value: language_uri,
                                      display: CONTROLLED_VOCABULARIES[:language].uri_to_text(language_uri))
  end
end
