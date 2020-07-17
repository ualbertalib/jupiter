class Collection < JupiterCore::Depositable

  acts_as_rdfable

  has_solr_exporter Exporters::Solr::CollectionExporter

  belongs_to :owner, class_name: 'User'
  belongs_to :community

  validates :title, presence: true
  validates :community_id, presence: true
  validate :community_validations

  before_destroy :can_be_destroyed?

  before_validation do
    self.visibility = JupiterCore::VISIBILITY_PUBLIC
  end

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

  def community_validations
    return unless community_id

    community = Community.find_by(id: community_id)
    errors.add(:community_id, :community_not_found, id: community_id) if community.blank?
  end

end
