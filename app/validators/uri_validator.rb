class UriValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    vocabs = options[:in_vocabularies]
    vocabs ||= [options[:in_vocabulary]]
    raise ArgumentError, "#{attr} must specify a vocabulary to validate against!" if vocabs.empty?
    return if value.blank?
    value = [value] unless value.is_a?(Array) || value.is_a?(ActiveTriples::Relation)

    value.each do |v|
      unless vocabs.any? { |vocab| ::CONTROLLED_VOCABULARIES[vocab].from_uri(v).present? }
        record.errors.add(attr, :not_recognized)
      end
    end
  end

end
