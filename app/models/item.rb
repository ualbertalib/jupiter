class Item < JupiterCore::Doiable

  acts_as_rdfable formats: :oai_dc

  has_solr_exporter Exporters::Solr::ItemExporter

  belongs_to :owner, class_name: 'User'

  has_many_attached :files, dependent: false

  has_paper_trail

  scope :public_items, -> { where(visibility: JupiterCore::VISIBILITY_PUBLIC) }
  # TODO: this (casting a json array to text and doing a LIKE against it) is kind of a nasty hack to deal with the fact
  # that production is currently using a 7 or 8 year old version of Postgresql (9.2) that lacks proper operators for
  # testing whether a value is in a json array, which newer version of Postgresql have.
  #
  # with an upgraded version of Postgresql this could be done more cleanly and performanetly
  scope :belongs_to_path, ->(path) { where('member_of_paths::text LIKE ?', "%#{path}%") }
  scope :updated_on_or_after, ->(date) { where('updated_at >= ?', date) }
  scope :updated_on_or_before, ->(date) { where('updated_at <= ?', date) }

  before_validation :populate_sort_year
  after_save :push_item_id_for_preservation

  validates :created, presence: true
  validates :sort_year, presence: true
  validates :languages, presence: true, uri: { in_vocabulary: :language }
  validates :item_type, presence: true, uri: { in_vocabulary: :item_type }
  validates :subject, presence: true
  validates :creators, presence: true
  validates :license, uri: { in_vocabularies: [:license, :old_license] }
  validates :publication_status, uri: { in_vocabulary: :publication_status }
  validates :publication_status, presence: { message: :required_for_article },
                                 if: ->(item) { item.item_type == CONTROLLED_VOCABULARIES[:item_type].article }
  validates :publication_status, absence: { message: :must_be_absent_for_non_articles },
                                 if: ->(item) { item.item_type != CONTROLLED_VOCABULARIES[:item_type].article }
  validates :publication_status, compound_uri: { compounds: [
    [CONTROLLED_VOCABULARIES[:publication_status].published],
    [CONTROLLED_VOCABULARIES[:publication_status].draft, CONTROLLED_VOCABULARIES[:publication_status].submitted]
  ] }, if: lambda { |item|
    item.item_type == CONTROLLED_VOCABULARIES[:item_type].article && item.publication_status.present?
  }

  validates_with LicenseXorRightsPresenceValidator

  validates :embargo_end_date, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
  validates :embargo_end_date, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
  validates :visibility_after_embargo, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
  validates :visibility_after_embargo, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
  validates :member_of_paths, presence: true
  validates :member_of_paths, community_and_collection_existence: true
  validates :visibility_after_embargo, known_visibility: { only: VISIBILITIES_AFTER_EMBARGO }

  def self.from_draft(draft_item)
    item = Item.find(draft_item.uuid) if draft_item.uuid.present?
    item ||= Item.new(id: draft_item.uuid)

    item.owner_id = draft_item.user_id if item.owner_id.blank?
    item.title = draft_item.title
    item.alternative_title = draft_item.alternate_title

    item.item_type = draft_item.item_type_as_uri
    item.publication_status = draft_item.publication_status_as_uri

    item.languages = draft_item.languages_as_uri
    item.creators = draft_item.creators
    item.subject = draft_item.subjects
    item.created = draft_item.date_created.to_s
    item.description = draft_item.description

    # Handle visibility plus embargo logic
    if draft_item.visibility_as_uri == CONTROLLED_VOCABULARIES[:visibility].embargo
      item.visibility_after_embargo = draft_item.visibility_after_embargo_as_uri
      item.embargo_end_date = draft_item.embargo_end_date
    else
      # If visibility was previously embargo but not anymore
      item.add_to_embargo_history if item.visibility == CONTROLLED_VOCABULARIES[:visibility].embargo
      item.visibility_after_embargo = nil
      item.embargo_end_date = nil
    end
    item.visibility = draft_item.visibility_as_uri

    # Handle license vs rights
    item.license = draft_item.license_as_uri
    item.rights = draft_item.license == 'license_text' ? draft_item.license_text_area : nil

    # Additional fields
    item.contributors = draft_item.contributors
    item.spatial_subjects = draft_item.places
    item.temporal_subjects = draft_item.time_periods
    # citations of previous publication apparently maps to is_version_of
    item.is_version_of = draft_item.citations
    item.source = draft_item.source
    item.related_link = draft_item.related_item

    item.member_of_paths = []

    draft_item.each_community_collection do |community, collection|
      item.add_to_path(community.id, collection.id)
    end

    item.logo_id = nil
    item.save!

    # remove old filesets and attachments and recreate
    # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
    # draft item
    item.files.each(&:destroy) if item.files.present?

    # add an association between the same underlying blobs the Draft uses and the Item
    draft_item.files_attachments.each do |attachment|
      ActiveStorage::Attachment.create(record: item,
                                       blob: attachment.blob,
                                       name: :files,
                                       fileset_uuid: UUIDTools::UUID.random_create)
    end

    item.set_thumbnail(item.files.find_by(blob_id: draft_item.thumbnail.blob.id)) if draft_item.thumbnail.present?

    draft_item.uuid = item.id
    draft_item.save!

    item
  end

  # This is stored in solr: combination of item_type and publication_status
  def item_type_with_status_code
    return nil if item_type.blank?

    # Return the item type code unless it's an article, then append publication status code
    item_type_code = CONTROLLED_VOCABULARIES[:item_type].from_uri(item_type)
    return item_type_code unless item_type_code == :article
    return nil if publication_status.blank?

    publication_status_code = CONTROLLED_VOCABULARIES[:publication_status].from_uri(publication_status.first)
    # Next line of code means that 'article_submitted' exists, but 'article_draft' doesn't ("There can be only one!")
    publication_status_code = :submitted if publication_status_code == :draft
    "#{item_type_code}_#{publication_status_code}".to_sym
  rescue ArgumentError
    nil
  end

  def all_subjects
    subject + temporal_subjects.to_a + spatial_subjects.to_a
  end

  def populate_sort_year
    self.sort_year = Date.parse(created).year.to_i if created.present?
  rescue ArgumentError
    # date was un-parsable, try to pull out the first 4 digit number as a year
    capture = created.scan(/\d{4}/)
    self.sort_year = capture[0].to_i if capture.present?
  end

  def add_to_path(community_id, collection_id)
    self.member_of_paths ||= []
    self.member_of_paths += ["#{community_id}/#{collection_id}"]
  end

  def self.valid_visibilities
    super + [VISIBILITY_EMBARGO]
  end

end
