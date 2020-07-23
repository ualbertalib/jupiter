class CommunityExistenceValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    value = [value] unless value.is_a?(Array)

    value.each do |community_id|
      community = Community.find_by(id: community_id)
      record.errors.add(attr, :community_not_found, id: community_id) if community.blank?
    end
  end

end
