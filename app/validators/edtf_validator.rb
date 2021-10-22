class EDTFValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if value.blank?

    value = [value] unless value.is_a?(Array)

    value.each do |date|
      next if date.blank?

      next unless Date.edtf(date).nil?

      record.errors.add(attribute, (
        options[:message] || 'does not conform to the Extended Date/Time Format standard'
      ))
    end
  end

end
