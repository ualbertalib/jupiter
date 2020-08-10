class ArCollection < ApplicationRecord

  has_solr_exporter Exporters::Solr::ArCollectionExporter

  acts_as_rdfable do |config|
    config.community_id has_predicate: ::TERMS[:ual].path
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.restricted has_predicate: ::TERMS[:ual].restricted_collection
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def self.from_collection(collection)
    if ArCollection.find_by(id: collection.id).present?
      raise ArgumentError, "Collection #{collection.id} already migrated"
    end

    ar_collection = ArCollection.new(id: collection.id)

    # this is named differently in ActiveFedora
    ar_collection.owner_id = collection.owner

    attributes = ar_collection.attributes.keys.reject { |k| ['owner_id', 'created_at', 'updated_at'].include?(k) }

    attributes.each do |attr|
      ar_collection.send("#{attr}=", collection.send(attr))
    end

    # unconditionally save. If something doesn't pass validations in ActiveFedora, it still needs to come here
    ar_collection.restricted ||= false
    ar_collection.save(validate: false)
    ar_collection
  end

end
