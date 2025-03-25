class Collection < JupiterCore::Depositable

  acts_as_rdfable

  has_solr_exporter Exporters::Solr::CollectionExporter

  belongs_to :owner, class_name: 'User'
  belongs_to :community

  validates :title, presence: true
  validates :community_id, community_existence: true

  before_destroy :can_be_destroyed?

  before_validation do
    self.visibility = JupiterCore::VISIBILITY_PUBLIC
  end

  after_save :push_entity_for_preservation
  after_save :update_member_objects_read_only

  # We have no attachments, so the scope is just the class itself.
  def self.eager_attachment_scope; self; end

  def path
    "#{community_id}/#{id}"
  end

  def member_items
    # TODO: this (casting a json array to text and doing a LIKE against it) is kind of a nasty hack to deal with the fact
    # that production is currently using a 7 or 8 year old version of Postgresql (9.2) that lacks proper operators for
    # testing whether a value is in a json array, which newer version of Postgresql have.
    #
    # with an upgraded version of Postgresql this could be done more cleanly and performanetly
    Item.where('member_of_paths::text LIKE ?', "%#{path}%")
  end

  def member_theses
    Thesis.where('member_of_paths::text LIKE ?', "%#{path}%")
  end

  def member_objects
    member_items + member_theses
  end

  def as_json(_options)
    super(only: [:title, :id])
  end

  def can_be_destroyed?
    return true if member_objects.count == 0

    errors.add(:member_objects, :must_be_empty,
               list_of_objects: member_objects.map(&:title).join(', '))
    throw(:abort)
  end

  def update_member_objects_read_only
    member_objects.each do |member_object|
      # Check if the object belongs to any other collections marked as read_only
      other_read_only_collections = []
      member_object.each_community_collection do |_, collection|
        other_read_only_collections << collection if collection.read_only? && collection != self
      end
      # Only update read_only to false if no other collections are read_only
      member_object.update(read_only: read_only) if read_only || other_read_only_collections.empty?
    end
  end

end
