class CompoundURIValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    ps_vocab = CONTROLLED_VOCABULARIES[:publication_status]
    value = [value] unless value.is_a?(Array)
    statuses = value.sort
    return unless statuses != [ps_vocab.published] && statuses != [ps_vocab.draft, ps_vocab.submitted]

    record.errors.add(attr, :not_recognized)
  end

end
