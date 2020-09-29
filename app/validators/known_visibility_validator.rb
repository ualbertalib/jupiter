class KnownVisibilityValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?
    # Test if the visibility value is present in a particular set of visibilities (passed as the 'only' list option)
    # useful for checks against after_embargo visibilities, etc.
    return if options[:only].present? && options[:only].include?(value)

    # Test if the visibility provided is valid for the current depositable model
    return if record.class.valid_visibilities.include?(value)

    record.errors.add(attr, I18n.t('locked_ldp_object.errors.invalid_visibility', visibility: value))
  end

end
