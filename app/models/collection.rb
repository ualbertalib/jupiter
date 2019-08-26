class Collection < Depositable

  scope :drafts, -> { where(is_published_in_era: false).or(where(is_published_in_era: nil)) }

  has_solr_exporter Exporters::Solr::CollectionExporter

  belongs_to :owner, class_name: 'User'

  validates :community_id, presence: true
  validate :community_validations

  before_validation do
    self.visibility = JupiterCore::VISIBILITY_PUBLIC
  end

  acts_as_rdfable do |config|
    config.community_id has_predicate: ::TERMS[:ual].path
    config.description has_predicate: ::RDF::Vocab::DC.description
    config.restricted has_predicate: ::TERMS[:ual].restricted_collection
    config.creators has_predicate: ::RDF::Vocab::DC.creator
  end

  def community
    Community.find(community_id)
  end

  def path
    "#{community_id}/#{id}"
  end

  def member_items
   Item.where("member_of_paths::text LIKE ?", "%#{path}%")
  end

  def member_theses
    Thesis.where("member_of_paths::text LIKE ?", "%#{path}%")
  end

  def member_objects
    member_items + member_theses.to_a
  end

  def as_json(_options)
    super(only: [:title, :id])
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

  def can_be_destroyed?
    return true if member_objects.count == 0

    errors.add(:member_objects, :must_be_empty,
               list_of_objects: member_objects.map(&:title).join(', '))
    throw(:abort)
  end

  def community_validations
    return unless community_id

    community = Community.find_by(id: community_id)
    errors.add(:community_id, :community_not_found, id: community_id) if community.blank?
  end

end
