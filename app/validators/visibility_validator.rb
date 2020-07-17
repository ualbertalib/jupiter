class VisibilityValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    value = [value] unless value.is_a?(Array)

    value.each do |visibility|
      unless visibility.present? && record.class.valid_visibilities.include?(visibility)
        record.errors.add(attr, I18n.t('locked_ldp_object.errors.invalid_visibility', visibility: visibility))
      end
    end
  end

end
