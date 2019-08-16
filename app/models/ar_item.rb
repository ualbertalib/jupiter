class ArItem < ApplicationRecord


# TODO: !!!!!!!!!!!!!!!!!
  has_solr_exporter Exporters::Solr::ArItemExporter

  belongs_to :owner, class_name: 'User'

  acts_as_rdfable do |config|
    config.title has_predicate: ::RDF::Vocab::DC.title
    config.creators has_predicate: RDF::Vocab::BIBO.authorList
    config.contributors has_predicate: ::RDF::Vocab::DC11.contributor
    # TODO
  #  config.date_created has_predicate: ::RDF::Vocab::DC.created
#    config.time_periods has_predicate: ::RDF::Vocab::DC.temporal
#    config.places has_predicate: ::RDF::Vocab::DC.spatial
    config.description has_predicate: ::RDF::Vocab::DC.description
    # TODO: add
    # config.publisher has_predicate: ::RDF::Vocab::DC.publisher
    # TODO join table
    # config.languages has_predicate: ::RDF::Vocab::DC.language
    config.license has_predicate: ::RDF::Vocab::DC.license
#config.type_id has_predicate: ::RDF::Vocab::DC.type
    config.source has_predicate: ::RDF::Vocab::DC.source
#    config.related_item has_predicate: ::RDF::Vocab::DC.relation
  #  config.status has_predicate: ::RDF::Vocab::BIBO.status
  end

  before_validation :populate_sort_year

  validates :created, presence: true
  validates :sort_year, presence: true
  validates :languages, presence: true, uri: { in_vocabulary: :language }
  validates :item_type, presence: true, uri: { in_vocabulary: :item_type }
  validates :subject, presence: true
  validates :creators, presence: true
  validates :license, uri: { in_vocabularies: [:license, :old_license] }
  validates :publication_status, uri: { in_vocabulary: :publication_status }
  validate :publication_status_presence,
           if: ->(item) { item.item_type == CONTROLLED_VOCABULARIES[:item_type].article }
  validate :publication_status_absence, if: ->(item) { item.item_type != CONTROLLED_VOCABULARIES[:item_type].article }
  validate :publication_status_compound_uri, if: lambda { |item|
    item.item_type == CONTROLLED_VOCABULARIES[:item_type].article && item.publication_status.present?
  }
  validate :license_xor_rights_must_be_present

  def self.from_draft(draft_item)
    #item = ArItem.find(draft_item.uuid) if draft_item.uuid.present?
    item ||= ArItem.new(id: draft_item.uuid)

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
    item.visibility = draft_item.visibility_as_uri
    item.visibility_after_embargo = draft_item.visibility_after_embargo_as_uri
    item.embargo_end_date = draft_item.embargo_end_date

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

    item.save!
    # remove old filesets and attachments and recreate

    # TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #item.purge_filesets
    # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
    # draft item
    #item.files.each(&:destroy) if item.files.present?

    # add an association between the same underlying blobs the Draft uses and the Item
    # draft_item.files_attachments.each do |attachment|
    #   new_attachment = ActiveStorage::Attachment.create(record: item.files_attachment_shim,
    #                                                     blob: attachment.blob, name: :shimmed_files)
    #   FileAttachmentIngestionJob.perform_later(new_attachment.id)
    # end
    #
    # item.set_thumbnail(item.files.find_by(blob_id: draft_item.thumbnail.blob.id))


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

  def license_xor_rights_must_be_present
    # Must have one of license or rights, not both
    if license.blank?
      errors.add(:base, :need_either_license_or_rights) if rights.blank?
    elsif rights.present?
      errors.add(:base, :not_both_license_and_rights)
    end
  end

  def publication_status_presence
    errors.add(:publication_status, :required_for_article) if publication_status.blank?
  end

  def publication_status_absence
    errors.add(:publication_status, :must_be_absent_for_non_articles) if publication_status.present?
  end

  def publication_status_compound_uri
    ps_vocab = CONTROLLED_VOCABULARIES[:publication_status]
    statuses = publication_status.sort
    return unless statuses != [ps_vocab.published] && statuses != [ps_vocab.draft, ps_vocab.submitted]

    errors.add(:publication_status, :not_recognized)
  end

  def add_to_path(community_id, collection_id)
    self.member_of_paths += ["#{community_id}/#{collection_id}"]
    # TODO: also add the collection (not the community) to the Item's memberOf relation, as metadata
    # wants to continue to model this relationship in pure PCDM terms, and member_of_path is really for our needs
    # so that we can facet by community and/or collection properly
    # TODO: add collection_id to member_of_collections
  end
end
