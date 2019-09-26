class Thesis < JupiterCore::Doiable
  acts_as_rdfable

  has_solr_exporter Exporters::Solr::ThesisExporter

  belongs_to :owner, class_name: 'User'

  has_many_attached :files, dependent: false

  scope :public_items, -> { where(visibility: JupiterCore::VISIBILITY_PUBLIC) }

  after_save :push_item_id_for_preservation
  before_validation :populate_sort_year

  validates :dissertant, presence: true
  validates :graduation_date, presence: true
  validates :sort_year, presence: true
  validates :language, uri: { in_vocabulary: :language }
  validates :institution, uri: { in_vocabulary: :institution }

  validates :embargo_end_date, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
  validates :embargo_end_date, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
  validates :visibility_after_embargo, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
  validates :visibility_after_embargo, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
  validates :member_of_paths, presence: true
  validate :communities_and_collections_must_exist
  validate :visibility_after_embargo_must_be_valid

  # Present a consistent interface with Item#item_type_with_status_code
  def item_type_with_status_code
    :thesis
  end

  def self.from_draft(draft_thesis)
    thesis = Thesis.find(draft_thesis.uuid) if draft_thesis.uuid.present?
    thesis ||= Thesis.new

    thesis.owner_id = draft_thesis.user_id if thesis.owner.blank?
    thesis.title = draft_thesis.title
    thesis.alternative_title = draft_thesis.alternate_title

    thesis.language = draft_thesis.language_as_uri
    thesis.dissertant = draft_thesis.creator
    thesis.abstract = draft_thesis.description

    thesis.graduation_date = if draft_thesis.graduation_term.present?
                               "#{draft_thesis.graduation_year}-#{draft_thesis.graduation_term}"
                             else
                               draft_thesis.graduation_year.to_s
                             end

    # Handle visibility plus embargo logic
    thesis.visibility = draft_thesis.visibility_as_uri

    if draft_thesis.embargo_end_date.present?
      thesis.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
    end

    thesis.embargo_end_date = draft_thesis.embargo_end_date

    # Handle rights
    thesis.rights = draft_thesis.rights

    # Additional fields
    thesis.date_accepted = draft_thesis.date_accepted
    thesis.date_submitted = draft_thesis.date_submitted

    thesis.degree = draft_thesis.degree
    thesis.thesis_level = draft_thesis.degree_level
    thesis.institution = draft_thesis.institution_as_uri
    thesis.specialization = draft_thesis.specialization

    thesis.subject = draft_thesis.subjects
    thesis.committee_members = draft_thesis.committee_members
    thesis.supervisors = draft_thesis.supervisors
    thesis.departments = draft_thesis.departments

    thesis.member_of_paths = []

    draft_thesis.each_community_collection do |community, collection|
      thesis.add_to_path(community.id, collection.id)
    end

    thesis.save!

    # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
    # draft item
    thesis.files.each(&:destroy) if thesis.files.present?

    # add an association between the same underlying blobs the Draft uses and the Item
    draft_thesis.files_attachments.each do |attachment|
      ActiveStorage::Attachment.create(record: thesis,
                                       blob: attachment.blob, name: :files)
    end

    thesis.set_thumbnail(thesis.files.find_by(blob_id: draft_thesis.thumbnail.blob.id))

    draft_thesis.uuid = thesis.id
    draft_thesis.save!
    thesis
  end

  def populate_sort_year
    self.sort_year = Date.parse(graduation_date).year.to_i if graduation_date.present?
    rescue ArgumentError
      # date was unparsable, try to pull out the first 4 digit number as a year
      capture = graduation_date.scan(/\d{4}/)
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
