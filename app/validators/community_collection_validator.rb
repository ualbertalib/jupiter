class CommunityCollectionValidator < ActiveModel::EachValidator

  def validate_each(record, attr, value)
    return if value.blank?

    value = [value] unless value.is_a?(Array)
    value.each do |path|
      community_id, collection_id = path.split('/')
      community = Community.find_by(id: community_id)
      record.errors.add(attr, :community_not_found, id: community_id) if community.blank?
      collection = Collection.find_by(id: collection_id)
      record.errors.add(attr, :collection_not_found, id: collection_id) if collection.blank?
    end
  end

end
