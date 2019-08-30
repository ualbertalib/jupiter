class ArCommunity < ApplicationRecord

  acts_as_rdfable do |config|
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def self.from_community(community)
    raise ArgumentError, "Community #{community.id} already migrated" if ArCommunity.find_by(id: community.id).present?

    ar_community = ArCommunity.new(id: community.id)

    # this is named differently in ActiveFedora
    ar_community.owner_id = community.owner

    attributes = ar_community.attributes.keys.reject do |k|
      ['owner_id', 'created_at', 'updated_at', 'logo_id'].include?(k)
    end

    attributes.each do |attr|
      ar_community.send("#{attr}=", community.send(attr))
    end

    # unconditionally save. If something doesn't pass validations in ActiveFedora, it still needs to come here
    ar_community.save(validate: false)

    # add an association between the same underlying blob the Community uses and the new ActiveRecord version
    if community.logo_attachment.present?
      new_attachment = ActiveStorage::Attachment.create(record: ar_community,
                                                        blob: community.logo_attachment.blob,
                                                        name: :logo,
                                                        fileset_uuid: community.logo_attachment.fileset_uuid)
      # because of the uuid id column, the record_id on new_attachment (currently of type integer), is broken
      # but that's ok. we're going to fix that with this data
      new_attachment.upcoming_record_id = ar_community.id
      new_attachment.save!
    end
    ar_community
  end

end
