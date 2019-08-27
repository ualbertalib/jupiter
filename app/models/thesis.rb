class Thesis < Depositable

  has_solr_exporter Exporters::Solr::ThesisExporter

  belongs_to :owner, class_name: 'User'

  has_many_attached :files, dependent: false

  scope :public_items, -> { where(visibility: JupiterCore::VISIBILITY_PUBLIC) }

  acts_as_rdfable do |config|
    config.title has_predicate: ::RDF::Vocab::DC.title
    # TODO
    #  config.date_created has_predicate: ::RDF::Vocab::DC.created
    #    config.time_periods has_predicate: ::RDF::Vocab::DC.temporal
    #    config.places has_predicate: ::RDF::Vocab::DC.spatial
  #  config.description has_predicate: ::RDF::Vocab::DC.description
    # TODO: add
    # config.publisher has_predicate: ::RDF::Vocab::DC.publisher
    # TODO join table
    # config.languages has_predicate: ::RDF::Vocab::DC.language
  #  config.license has_predicate: ::RDF::Vocab::DC.license
    # config.type_id has_predicate: ::RDF::Vocab::DC.type
#    config.source has_predicate: ::RDF::Vocab::DC.source
#    #    config.related_item has_predicate: ::RDF::Vocab::DC.relation
    #  config.status has_predicate: ::RDF::Vocab::BIBO.status
  end

  before_validation :populate_sort_year

  # Present a consistent interface with Item#item_type_with_status_code
  def item_type_with_status_code
    :thesis
  end

  def self.from_draft(draft_thesis)
    thesis = Thesis.find(draft_thesis.uuid) if draft_thesis.uuid.present?
    thesis ||= Thesis.new
    thesis.unlock_and_fetch_ldp_object do |unlocked_obj|
      unlocked_obj.owner_id = draft_thesis.user_id if unlocked_obj.owner.blank?
      unlocked_obj.title = draft_thesis.title
      unlocked_obj.alternative_title = draft_thesis.alternate_title

      unlocked_obj.language = draft_thesis.language_as_uri
      unlocked_obj.dissertant = draft_thesis.creator
      unlocked_obj.abstract = draft_thesis.description

      unlocked_obj.graduation_date = if draft_thesis.graduation_term.present?
                                       "#{draft_thesis.graduation_year}-#{draft_thesis.graduation_term}"
                                     else
                                       draft_thesis.graduation_year.to_s
                                     end

      # Handle visibility plus embargo logic
      unlocked_obj.visibility = draft_thesis.visibility_as_uri

      if draft_thesis.embargo_end_date.present?
        unlocked_obj.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
      end

      unlocked_obj.embargo_end_date = draft_thesis.embargo_end_date

      # Handle rights
      unlocked_obj.rights = draft_thesis.rights

      # Additional fields
      unlocked_obj.date_accepted = draft_thesis.date_accepted
      unlocked_obj.date_submitted = draft_thesis.date_submitted

      unlocked_obj.degree = draft_thesis.degree
      unlocked_obj.thesis_level = draft_thesis.degree_level
      unlocked_obj.institution = draft_thesis.institution_as_uri
      unlocked_obj.specialization = draft_thesis.specialization

      unlocked_obj.subject = draft_thesis.subjects
      unlocked_obj.committee_members = draft_thesis.committee_members
      unlocked_obj.supervisors = draft_thesis.supervisors
      unlocked_obj.departments = draft_thesis.departments

      unlocked_obj.member_of_paths = []

      draft_thesis.each_community_collection do |community, collection|
        unlocked_obj.add_to_path(community.id, collection.id)
      end

      unlocked_obj.save!

      # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
      # draft item
      thesis.files.each(&:destroy) if thesis.files.present?

      # add an association between the same underlying blobs the Draft uses and the Item
      draft_thesis.files_attachments.each do |attachment|
        new_attachment = ActiveStorage::Attachment.create(record: thesis.files_attachment_shim,
                                                          blob: attachment.blob, name: :shimmed_files)
        FileAttachmentIngestionJob.perform_later(new_attachment.id)
      end

      thesis.set_thumbnail(thesis.files.find_by(blob_id: draft_thesis.thumbnail.blob.id))
    end

    draft_thesis.uuid = thesis.id
    draft_thesis.save!
    thesis
  end

  after_save :push_item_id_for_preservation

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
