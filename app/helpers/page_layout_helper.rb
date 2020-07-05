module PageLayoutHelper
  # Rubocop now wants us to remove instance methods from helpers. This is a good idea
  # but will require a bit of refactoring. Find other instances of this disabling
  # and fix all at once.
  # rubocop:disable Rails/HelperInstanceVariable
  def page_title(title = nil)
    # title tags should be around 55 characters, so lets truncate them if they quite long
    # With '... | ERA' being appended, we want to aim for a bit smaller like 45 characters
    title = truncate(strip_tags(title), length: 45, separator: ' ', omission: '...', escape: false)

    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end
  # rubocop:enable Rails/HelperInstanceVariable

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
  # rubocop:disable Rails/HelperInstanceVariable
  def page_description(description = nil)
    if description.present?
      @page_description = description.squish
    elsif @page_description.present?
      truncate(strip_tags(@page_description), length: 140, separator: ' ', omission: '...', escape: false)
    else
      @page_description = t('welcome.index.welcome_lead')
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def thumbnail_path(logo, args = { resize_to_limit: [100, 100], auto_orient: true })
    return nil if logo.blank?

    # images have variants
    Rails.application.routes.url_helpers.rails_representation_path(logo.variant(args).processed)
  rescue ActiveStorage::InvariableError
    begin
      # pdfs and video have previews
      Rails.application.routes.url_helpers.rails_representation_path(logo.preview(args).processed)
    # ActiveStorage::UnpreviewableError and sometimes MiniMagick::Error gets thrown here
    rescue StandardError => e
      logger.warn("#{logo.record_type} with id: #{logo.record_id} and thumnail #{logo.name} \
      threw an error after ActiveStorage::InvariableError.")
      Rollbar.warn("#{logo.record_type} with id: #{logo.record_id} and thumnail #{logo.name} \
      threw an error after ActiveStorage::InvariableError.", e)
      nil
    end
  rescue StandardError => e
    logger.warn("#{logo.record_type} with id: #{logo.record_id} and thumnail #{logo.name} threw an error.")
    Rollbar.warn("#{logo.record_type} with id: #{logo.record_id} and thumnail #{logo.name} threw an error.", e)
    nil
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def page_image_url
    default_url = asset_pack_url('media/images/era-logo.png')
    # We only have images on community and item/thesis show pages
    image_path = thumbnail_path(@community&.thumbnail_file) || thumbnail_path(@item&.thumbnail_file)

    image_path ? request.base_url + image_path : default_url
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def page_type(type = nil)
    type || 'website'
  end

  def canonical_href(request_path = request.path)
    "#{Jupiter::PRODUCTION_URL}#{request_path == '/' ? '' : request_path}"
  end
end
