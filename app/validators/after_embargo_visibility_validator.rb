class AfterEmbargoVisibilityValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    visibilities_after_embargo = options[:visibilities_after_embargo]
    if visibilities_after_embargo.empty?
      raise ArgumentError, "#{attr} must specify the list of visibilities after embargo to check against!"
    end

    value = [value] unless value.is_a?(Array)

    value.each do |visibility|
      record.errors.add(attr, :not_recognized) unless visibilities_after_embargo.include?(visibility)
    end
  end

end
