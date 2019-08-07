class DraftCommunity < ApplicationRecord

  acts_as_rdfable do |config|
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def update_from_fedora_community(community, _for_user)
    draft_attributes = {
      community_id: community.id,
      visibility: community.visibility,
      owner_id: community.owner,
      record_created_at: community.record_created_at,
      hydra_noid: community.hydra_noid,
      date_ingested: community.date_ingested,
      title: community.title,
      fedora3_uuid: community.fedora3_uuid,
      depositor_id: community.depositor,
      description: community.description,
      creators: community.creators
    }
    assign_attributes(draft_attributes)
    save(validate: false)
  end

  def self.from_community(community, for_user:)
    draft = DraftCommunity.find_by(community_id: community.id)
    draft ||= DraftCommunity.new(community_id: community.id)

    draft.update_from_fedora_community(community, for_user)
    draft
  end

end
