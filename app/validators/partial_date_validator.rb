class PartialDateValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    # validate formats 'YYYY-MM-DD', 'YYYY-MM', and 'YYYY'

    if value.blank?
      record.errors.add(attribute, "must be format 'YYYY-MM-DD', 'YYYY-MM', or 'YYYY': '#{value}'")
    else
      # Note that are adding the month and day values when they are not
      # presentwe because we use the Date.parse method for convenience.
      # However, we do not enforce the full date value to have the format
      # 'YYYY-MM-DD'
      year, month, day = value.split('-')
      month ||= '01'
      day ||= '01'

      unless /\A\d{4}\z/.match?(year) && /\A\d{2}\z/.match?(month) && /\A\d{2}\z/.match?(day)
        record.errors.add(attribute, "must be format 'YYYY-MM-DD', 'YYYY-MM', or 'YYYY': '#{value}'")
      end

      begin
        Date.parse("#{year}-#{month}-#{day}")
      rescue Date::Error
        record.errors.add(attribute, "is not a valid date: '#{value}'")
      end
    end
  end

end
