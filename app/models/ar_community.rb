class ArCommunity < ApplicationRecord

  scope :drafts, -> { where(is_published_in_era: false).or(where(is_published_in_era: nil)) }

  acts_as_rdfable do |config|
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def update_from_fedora_community(community)
    attributes = {
      visibility: community.visibility,
      owner_id: community.owner,
      record_created_at: community.record_created_at,
      hydra_noid: community.hydra_noid,
      date_ingested: community.date_ingested,
      title: community.title,
      fedora3_uuid: community.fedora3_uuid,
      depositor: community.depositor,
      description: community.description,
      creators: community.creators,
      is_published_in_era: true
    }
    assign_attributes(attributes)
    save(validate: false)
  end

  def self.from_community(community)
    new_ar_community = ArCommunity.drafts.find_by(id: community.id)
    new_ar_community ||= ArCommunity.drafts.new(id: community.id)

    new_ar_community.update_from_fedora_community(community)
    new_ar_community
  end

end
