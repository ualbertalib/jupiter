module ApplicationHelper
  TRUNCATE_CHARS_DEFAULT = 300

  def humanize_uri_code(namespace, vocab, code)
    t("controlled_vocabularies.#{namespace}.#{vocab}.#{code}")
  end

  def humanize_uri(namespace, vocab, uri)
    val, is_i18n = ControlledVocabulary.value_from_uri(namespace: namespace, vocab: vocab, uri: uri)
    return nil if val.nil?

    return val unless is_i18n

    humanize_uri_code(namespace, vocab, val)
  end

  def humanize_uri_or_literal(namespace, vocab, uri_or_literal)
    literal_from_uri = humanize_uri(namespace, vocab, uri_or_literal)
    return literal_from_uri if literal_from_uri.present?

    uri_or_literal
  end

  def help_tooltip(text)
    tag.span(icon('fas', 'question-circle'), title: text)
  end

  # Simple wrapper around time_tag and time_ago_in_words to handle nil case (otherwise time_tag 500s)
  # TODO: expand this to include displaying of a nice tooltip/title
  # Issue here: https://github.com/ualbertalib/jupiter/issues/159
  def jupiter_time_tag(date, format: '%F', blank_message: '')
    return blank_message if date.blank?

    time_tag(date, format: format)
  end

  def jupiter_time_ago_in_words(date, blank_message: '')
    return blank_message if date.blank?

    t('time_ago', time: time_ago_in_words(date))
  end

  def results_range(results)
    # results come from a Jupiter query/search with pagination
    first = results.offset_value + 1
    last = results.offset_value + results.count
    t(:page_range, first: first, last: last, total: results.total_count)
  end

  def search_link_for(object, attribute, value: nil, facet: :facet, display: nil)
    value ||= object.send(attribute)
    display ||= value
    case facet
    when :range_facet
      link_to(display, search_path(ranges: object.solr_exporter_class.facet_term_for(attribute,
                                                                                     value,
                                                                                     role: :range_facet)),
              rel: 'nofollow')
    when :facet
      link_to(display, search_path(facets: object.solr_exporter_class.facet_term_for(attribute, value)),
              rel: 'nofollow')
    else
      link_to(display, search_path(search: object.solr_exporter_class.search_term_for(attribute, value)),
              rel: 'nofollow')
    end
  end

  def jupiter_truncate(text, length: TRUNCATE_CHARS_DEFAULT, separator: ' ', omission: '...')
    truncate text, length: length, separator: separator, omission: omission
  end
end
