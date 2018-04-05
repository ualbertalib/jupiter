module ApplicationHelper
  include PresentersHelper

  TRUNCATE_CHARS_DEFAULT = 300

  def page_title(title)
    # title tags should be around 55 characters, so lets truncate them if they quite long
    # With '... | ERA' being appended, we want to aim for a bit smaller like 45 characters
    title = jupiter_truncate(title, length: 45) if title.length > 45

    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end

  # Define or get a description for the current page
  #
  # description - String (default: nil)
  #
  # If this helper is called multiple times with an argument, only the last
  # description will be returned when called without an argument. Descriptions
  # have newlines replaced with spaces and all HTML tags are sanitized.
  #
  # Examples:
  #
  #   page_description # => "Default Jupiter Welcome Lead"
  #   page_description("Foo")
  #   page_description # => "Foo"
  #
  #   page_description("<b>Bar</b>\nBaz")
  #   page_description # => "Bar Baz"
  #
  # Returns an HTML-safe String.
  def page_description(description = nil)
    if description.present?
      @page_description = description.squish
    elsif @page_description.present?
      jupiter_truncate(sanitize(@page_description), length: 140)
    else
      @page_description = t('welcome.index.welcome_lead')
    end
  end

  def humanize_uri_code(vocab, code)
    t("controlled_vocabularies.#{vocab}.#{code}")
  end

  def humanize_uri(vocab, uri)
    code = CONTROLLED_VOCABULARIES[vocab].from_uri(uri)
    return nil if code.nil?
    humanize_uri_code(vocab, code)
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
      link_to(display, search_path(facets: object.class.facet_term_for(attribute, value)), rel: 'nofollow')
    else
      link_to(display, search_path(search: object.class.search_term_for(attribute, value)), rel: 'nofollow')
    end
  end

  def jupiter_truncate(text, length: TRUNCATE_CHARS_DEFAULT, separator: ' ', omission: '...')
    truncate text, length: length, separator: separator, omission: omission
  end
end
