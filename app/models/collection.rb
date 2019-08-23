class Collection < Depositable

  scope :drafts, -> { where(is_published_in_era: false).or(where(is_published_in_era: nil)) }

  has_solr_exporter Exporters::Solr::CollectionExporter

  belongs_to :owner, class_name: 'User'


  acts_as_rdfable do |config|
    config.community_id has_predicate: ::TERMS[:ual].path
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.restricted has_predicate: ::TERMS[:ual].restricted_collection
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def update_from_fedora_collection(collection)
    attributes = {
      collection_id: collection.id,
      visibility: collection.visibility,
      owner_id: collection.owner,
      record_created_at: collection.record_created_at,
      hydra_noid: collection.hydra_noid,
      date_ingested: collection.date_ingested,
      title: collection.title,
      fedora3_uuid: collection.fedora3_uuid,
      depositor_id: collection.depositor,
      community_id: collection.community_id,
      description: collection.description,
      creators: collection.creators,
      restricted: (collection.restricted || false)
    }
    assign_attributes(attributes)
    save(validate: false)
  end

  def self.from_collection(collection)
    new_ar_collection = ArCollection.drafts.find_by(collection_id: collection.id)
    new_ar_collection ||= ArCollection.drafts.new(collection_id: collection.id)

    new_ar_collection.update_from_fedora_collection(collection)
    new_ar_collection
  end

end
