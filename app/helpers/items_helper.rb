module ItemsHelper
  def item_type_search_link(item)
    search_link_for(item, :item_type_with_status,
                    value: item.item_type_with_status_code,
                    display: t("controlled_vocabularies.item_type_with_status.#{item.item_type_with_status_code}"))
  end

  def language_search_link(item, language_uri)
    search_link_for(item, :languages, value: language_uri, display: humanize_uri(:language, language_uri))
  end

  def license_link(license)
    text = humanize_uri(:license, license)
    text ||= humanize_uri(:old_license, license)
    text ||= license
    link_to(text, license)
  end

  def description(object)
    return object.abstract if object.respond_to? :abstract
    return object.description if object.respond_to? :description
  end

  # We have a lot of messy "date-ish" data. Created dates coming through the Draft interface are actual date types
  # saved into Fedora/Solr as strings at the moment. Much of the legacy data is generally a freeform string containing
  # anything from "2017/09/12" to '2013' to "2012-09-26T11:18:38Z" (on Theses) to "Fall 1978" to '1978-11' to "Unknown"
  # to "Late Roman antiquity" (ok, I'm making that one up, but it wouldn't surprise me).
  #
  # This complicates displaying the field because if we display the raw data we end up displaying decidedly unfriendly
  # things like "1986-11-17 14:51:45 -0700" in cases where higher quality dates were recorded.
  #
  # Thus, we first try to parse the date and display a simple iso8601 formated date if it succeeds.
  # If this fails we try to parse the date as a graduation term and display it in the prefered format.
  # Finally we fall back to displaying raw data otherwise.
  def humanize_date(dateish)
    return I18n.t('date_unknown') if dateish.blank?

    begin
      Date.parse(dateish).iso8601
    rescue ArgumentError
      term = Date.strptime(dateish, '%Y-%m')

      # Fall back to just YYYY for any other value of MM or when MM is absent.
      "#{SEASON[term.month]} #{term.year}".strip
    end
  rescue ArgumentError
    dateish
  end

  # TODO: this might seem redundant with DraftThesis::TERMS but this is the inverse
  # and at the time this was added the graduation term for draft thesis looks like '06 (Spring)'
  # which isn't exactly what we want.
  SEASON = {
    6 => I18n.t('items.thesis.graduation_terms.spring'),
    11 => I18n.t('items.thesis.graduation_terms.fall')
  }.freeze
end
