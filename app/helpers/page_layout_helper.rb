module PageLayoutHelper
  def page_title(title = nil)
    # title tags should be around 55 characters, so lets truncate them if they quite long
    # With '... | ERA' being appended, we want to aim for a bit smaller like 45 characters
    title = truncate(strip_tags(title), length: 45, separator: ' ', omission: '...', escape: false)

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
      truncate(strip_tags(@page_description), length: 140, separator: ' ', omission: '...', escape: false)
    else
      @page_description = t('welcome.index.welcome_lead')
    end
  end

  def page_image
    default_url = image_url('era-logo.png')
    # We only have images on community and item/thesis show pages
    image = @community&.logo_attachment || @item&.thumbnail_attachment
    image_url = rails_blob_url(image) if image.present?
    image_url || default_url
  end

  def page_type(type = nil)
    type || 'website'
  end
end
