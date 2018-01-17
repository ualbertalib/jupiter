module ApplicationHelper
  include PresentersHelper

  TRUNCATE_CHARS_DEFAULT = 300

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

  def thesis_path(result)
    # Theses are viewed with the item controller, which breaks the `polymorphic_path` above
    item_path(result)
  end

  def help_tooltip(text)
    content_tag(:span, fa_icon('question-circle'), title: text)
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

  def search_link_for(object, attribute, value: nil, facet: true, display: nil)
    value ||= object.send(attribute)
    display ||= value
    if facet
      link_to(display, search_path(facets: object.class.facet_term_for(attribute, value)))
    else
      link_to(display, search_path(search: object.class.search_term_for(attribute, value)))
    end
  end

  def jupiter_truncate(text, length: TRUNCATE_CHARS_DEFAULT, separator: ' ', omission: '...')
    truncate text, length: length, separator: separator, omission: omission
  end
end
