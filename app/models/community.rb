class Community < JupiterCore::Depositable

  acts_as_rdfable

  has_solr_exporter Exporters::Solr::CommunityExporter

  belongs_to :owner, class_name: 'User'

  # technically this could be dependent: :restrict_with_error, but we already handle this with a custom validation & error message
  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :collections
  # rubocop:enable Rails/HasManyOrHasOneDependent

  has_one_attached :logo

  before_destroy :can_be_destroyed?
  before_destroy -> { logo.purge_later }

  validates :title, presence: true

  before_validation do
    self.visibility = JupiterCore::VISIBILITY_PUBLIC
  end

  def self.eager_attachment_scope
    with_attached_logo
  end

  def self.safe_attributes
    super + [:logo, :remove_logo]
  end

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    collections
  end

  # A virtual attribute to handle removing logos on forms ...
  def remove_logo
    # Never want the checkbox checked by default
    false
  end

  def remove_logo=(val)
    return unless logo.attached? && (val == 'true')

    # This should probably be 'purge_later', but then we have problems on page reload
    logo_attachment.purge
  end

  def thumbnail_file
    logo.attachment
  end

  def can_be_destroyed?
    return true if member_collections.count == 0

    errors.add(:member_collections, :must_be_empty,
               list_of_collections: member_collections.map(&:title).join(', '))
    throw(:abort)
  end

end
