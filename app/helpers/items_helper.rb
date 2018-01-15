module ItemsHelper
  def item_type_search_link(item)
    search_link_for(item, :item_type_with_status,
                    value: item.item_type_with_status_code,
                    display: t("controlled_vocabularies.item_type_with_status.#{item.item_type_with_status_code}"))
  end

  def language_search_link(item, language_uri, attribute: :languages)
    search_link_for(item, attribute, value: language_uri,
                                     display: CONTROLLED_VOCABULARIES[:language].uri_to_text(language_uri))
  end

  def license_link(license)
    text = CONTROLLED_VOCABULARIES[:license].uri_to_text(license, raise_error_on_missing: false)
    text ||= CONTROLLED_VOCABULARIES[:old_license].uri_to_text(license, raise_error_on_missing: false)
    text ||= license
    link_to(text, license)
  end
end
