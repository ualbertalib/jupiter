module ItemsHelper
  def item_type_search_link(item)
    search_link_for(item, :item_type_with_status,
                    value: item.item_type_with_status_code,
                    display: t("controlled_vocabularies.item_type_with_status.#{item.item_type_with_status_code}"))
  end

  def language_search_link(item, language_uri)
    search_link_for(item, :languages, value: language_uri,
                                      display: humanize_uri(:language, language_uri))
  end

  def license_link(license)
    text = humanize_uri(:license, license)
    text ||= humanize_uri(:old_license, license)
    text ||= license
    link_to(text, license)
  end

  def authors(object)
    return [object.dissertant] if object.respond_to? :dissertant
    return object.creators if object.respond_to? :creators
  end

  def description(object)
    return object.abstract if object.respond_to? :abstract
    return object.description if object.respond_to? :description
  end
end
