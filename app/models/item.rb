class Item < JupiterCore::LockedLdpObject

  include ObjectProperties
  include ItemProperties
  include GlobalID::Identification
  ldp_object_includes Hydra::Works::WorkBehavior

  has_solr_exporter :item_exporter

  # Contributors (faceted in `all_contributors`)
  has_attribute :creators, RDF::Vocab::BIBO.authorList, type: :json_array, solrize_for: [:search]
  # copying the creator values into an un-json'd field for Metadata consumption
  has_multival_attribute :unordered_creators, ::RDF::Vocab::DC11.creator, solrize_for: [:search]
  has_multival_attribute :contributors, ::RDF::Vocab::DC11.contributor, solrize_for: [:search]

  has_attribute :created, ::RDF::Vocab::DC.created, solrize_for: [:search, :sort]

  # Subject types (see `all_subjects` for faceting)
  has_multival_attribute :temporal_subjects, ::RDF::Vocab::DC.temporal, solrize_for: [:search]
  has_multival_attribute :spatial_subjects, ::RDF::Vocab::DC.spatial, solrize_for: [:search]

  has_attribute :description, ::RDF::Vocab::DC.description, type: :text, solrize_for: :search
  has_attribute :publisher, ::RDF::Vocab::DC.publisher, solrize_for: [:search, :facet]
  # has_attribute :date_modified, ::RDF::Vocab::DC.modified, type: :date, solrize_for: :sort
  has_multival_attribute :languages, ::RDF::Vocab::DC.language, solrize_for: [:search, :facet]
  has_attribute :license, ::RDF::Vocab::DC.license, solrize_for: [:search]

  # `type` is an ActiveFedora keyword, so we call it `item_type`
  # Note also the `item_type_with_status` below for searching, faceting and forms
  has_attribute :item_type, ::RDF::Vocab::DC.type, solrize_for: :exact_match
  has_attribute :source, ::RDF::Vocab::DC.source, solrize_for: :exact_match
  has_attribute :related_link, ::RDF::Vocab::DC.relation, solrize_for: :exact_match

  # Bibo attributes
  # This status is only for articles: either 'published' (alone) or two triples for 'draft'/'submitted'
  has_multival_attribute :publication_status, ::RDF::Vocab::BIBO.status, solrize_for: :exact_match

  # Solr only
  additional_search_index :doi_without_label, solrize_for: :exact_match,
                                              as: -> { doi.gsub('doi:', '') if doi.present? }

  # This combines both the controlled vocabulary codes from item_type and published_status above
  # (but only for items that are articles)
  additional_search_index :item_type_with_status,
                          solrize_for: :facet,
                          as: -> { item_type_with_status_code }

  # Combine creators and contributors for faceting (Thesis also uses this index)
  # Note that contributors is converted to an array because it can be nil
  additional_search_index :all_contributors, solrize_for: :facet, as: -> { creators + contributors.to_a }

  # Combine all the subjects for faceting
  additional_search_index :all_subjects, solrize_for: :facet, as: -> { all_subjects }

  def self.from_draft(draft_item)
    item = Item.find(draft_item.uuid) if draft_item.uuid.present?
    item ||= Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_obj|
      unlocked_obj.owner = draft_item.user_id if unlocked_obj.owner.blank?
      unlocked_obj.title = draft_item.title
      unlocked_obj.alternative_title = draft_item.alternate_title

      unlocked_obj.item_type = draft_item.item_type_as_uri
      unlocked_obj.publication_status = draft_item.publication_status_as_uri

      unlocked_obj.languages = draft_item.languages_as_uri
      unlocked_obj.creators = draft_item.creators
      unlocked_obj.subject = draft_item.subjects
      unlocked_obj.created = draft_item.date_created.to_s
      unlocked_obj.description = draft_item.description

      # Handle visibility plus embargo logic
      if draft_item.visibility_as_uri == CONTROLLED_VOCABULARIES[:visibility].embargo
        unlocked_obj.visibility_after_embargo = draft_item.visibility_after_embargo_as_uri
        unlocked_obj.embargo_end_date = draft_item.embargo_end_date
      else
        # If visibility was previously embargo but not anymore
        unlocked_obj.add_to_embargo_history if unlocked_obj.visibility == CONTROLLED_VOCABULARIES[:visibility].embargo
        unlocked_obj.visibility_after_embargo = nil
        unlocked_obj.embargo_end_date = nil
      end
      unlocked_obj.visibility = draft_item.visibility_as_uri

      # Handle license vs rights
      unlocked_obj.license = draft_item.license_as_uri
      unlocked_obj.rights = draft_item.license == 'license_text' ? draft_item.license_text_area : nil

      # Additional fields
      unlocked_obj.contributors = draft_item.contributors
      unlocked_obj.spatial_subjects = draft_item.places
      unlocked_obj.temporal_subjects = draft_item.time_periods
      # citations of previous publication apparently maps to is_version_of
      unlocked_obj.is_version_of = draft_item.citations
      unlocked_obj.source = draft_item.source
      unlocked_obj.related_link = draft_item.related_item

      unlocked_obj.member_of_paths = []

      draft_item.each_community_collection do |community, collection|
        unlocked_obj.add_to_path(community.id, collection.id)
      end

      unlocked_obj.save!
      # remove old filesets and attachments and recreate
      unlocked_obj.purge_filesets
      # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
      # draft item
      item.files.each(&:destroy) if item.files.present?

      # add an association between the same underlying blobs the Draft uses and the Item
      draft_item.files_attachments.each do |attachment|
        new_attachment = ActiveStorage::Attachment.create(record: item.files_attachment_shim,
                                                          blob: attachment.blob, name: :shimmed_files)
        FileAttachmentIngestionJob.perform_later(new_attachment.id)
      end

      item.set_thumbnail(item.files.find_by(blob_id: draft_item.thumbnail.blob.id))
    end

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

  unlocked do
    before_validation :populate_sort_year
    before_save :copy_creators_to_unordered_predicate

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

    def populate_sort_year
      self.sort_year = Date.parse(created).year.to_i if created.present?
    rescue ArgumentError
      # date was un-parsable, try to pull out the first 4 digit number as a year
      capture = created.scan(/\d{4}/)
      self.sort_year = capture[0].to_i if capture.present?
    end

    def copy_creators_to_unordered_predicate
      return unless creators_changed?

      self.unordered_creators = []
      creators.each { |c| self.unordered_creators += [c] }
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
  end

end
