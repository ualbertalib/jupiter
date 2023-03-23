class URIValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    namespace = options[:namespace]
    vocabs = options[:in_vocabularies]
    vocabs ||= [options[:in_vocabulary]]
    raise ArgumentError, "#{attr} must specify a vocabulary to validate against!" if vocabs.empty?

    value = [value] unless value.is_a?(Array)

    value.each do |v|
      record.errors.add(attr, :not_recognized) unless vocabs.any? do |vocab|
        val, _ = ControlledVocabulary.value_from_uri(namespace: namespace, vocab: vocab, uri: v)
        val.present?
      end
    end
  end

end
