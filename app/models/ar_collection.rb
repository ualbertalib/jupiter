class ArCollection < ApplicationRecord

  acts_as_rdfable do |config|
    config.community_id has_predicate: ::TERMS[:ual].path
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.restricted has_predicate: ::TERMS[:ual].restricted_collection
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def self.from_collection(collection)
    raise ArgumentError, "Community #{collection.id} already migrated to ActiveRecord" if ArCollection.find_by(id: item.id) != nil

    ar_collection = ArCollection.new(id: collection.id)

    # this is named differently in ActiveFedora
    ar_collection.owner_id = collection.owner

    attributes = ar_collection.attributes.keys.reject {|k| k == 'owner_id' || k == 'created_at' || k == 'updated_at'}

    attributes.each do |attr|
      ar_collection.send("#{attr}=", collection.send(attr))
    end

    # unconditionally save. If something doesn't pass validations in ActiveFedora, it still needs to come here
    ar_collection.save(validate: false)
  end

end
