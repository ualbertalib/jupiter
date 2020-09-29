class CompoundURIValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    compounds = options[:compounds]

    raise ArgumentError, "#{attr} must specify the list of compounds to check against!" if compounds.empty?

    compounds = [compounds] unless value.is_a?(Array)
    value = [value] unless value.is_a?(Array)

    return if compounds.map(&:sort).include?(value.sort)

    record.errors.add(attr, :not_recognized)
  end

end
