class DraftItem < ApplicationRecord

  enum status: { inactive: 0, active: 1, archived: 2 }

  enum wizard_step: { describe_item: 0, choose_license_and_visibility: 1, upload_files: 2, review_and_deposit_item: 3 }

  enum license: { attribution_non_commercial: 0,
                  attribution: 1,
                  attribution_non_commercial_no_derivatives: 2,
                  attribution_non_commercial_share_alike: 3,
                  attribution_no_derivatives: 4,
                  attribution_share_alike: 5,
                  cco_universal: 6,
                  public_domain_mark: 7,
                  license_text: 8 }

  # Can't use public as this is a ActiveRecord method, using open_access instead
  enum visibility: { open_access: 0,
                     embargo: 1,
                     authenticated: 2 }

  # Can't reuse same keys as visibility enum above, need to differentiate keys a bit
  #
  # According to requirement's this will not be set from the UI
  # By default it will always be in `public`/`opened` status
  # Only needed for for the odd chance they want to change an item's visibility_after_embargo
  # to `ccid_authenticated`/`authenticated` from the console
  enum visibility_after_embargo: { opened: 0,
                                   ccid_protected: 1 }

  has_many_attached :files

  has_many :draft_items_languages, dependent: :destroy

  has_many :languages, through: :draft_items_languages

  # Rails 5 turns presence check on by default for belongs_to relationships
  belongs_to :type, optional: true
  belongs_to :user

  validates :title, :type, :languages,
            :creators, :subjects, :date_created,
            :description, :member_of_paths,
            presence: true, if: :validate_describe_item?

  validate :communities_and_collections_validations, if: :validate_describe_item?

  validates :license, :visibility, presence: true, if: :validate_choose_license_and_visibility?
  validates :license_text_area, presence: true, if: :validate_if_license_is_text?
  validates :embargo_end_date, presence: true, if: :validate_if_visibility_is_embargo?

  validates :files, presence: true, if: :validate_upload_files?

  def thumbnail
    if thumbnail_id.present?
      # TODO: Weird bug with activestorage when walking the assocation to all the attachments
      # Should be able to just do `files.where` or `files.find_by` but what returns
      # is either an Attachment class (expected) or an Enumerator (?).
      # Easier just to get it directly from active storages table instead
      file = ActiveStorage::Attachment.find_by(id: thumbnail_id)
      return file if file.present?
    end

    files.first
  end

  def uncompleted_step?(step)
    # Bit confusing here, but when were in an active state, aka draft item has data,
    # the step saved on the object is actually a step behind. As it is only updated on an update for a new step.
    # Hence we just do current step + one to get the actual step here.
    # For an inactive/archived state we are what is expected as we are starting/ending on the same step as what's saved in the object
    if active?
      DraftItem.wizard_steps[wizard_step] + 1 < DraftItem.wizard_steps[step]
    else
      DraftItem.wizard_steps[wizard_step] < DraftItem.wizard_steps[step]
    end
  end

  def last_completed_step
    # Comment above in uncompleted_step? applies here with regards to the extra logic around active state
    # and getting the next step instead of the current step
    if active?
      DraftItem.wizard_steps.key(DraftItem.wizard_steps.fetch(wizard_step) + 1).to_sym
    else
      wizard_step
    end
  end

  # Creates an Item object from the draft_item attributes
  def ingest_into_fedora
    Item.new_locked_ldp_object(
      owner: user.id,

      title: title,
      alternative_title: alternate_title,

      item_type: item_type_conversion_to_controlled_vocab_uri,
      publication_status: handle_publication_status,

      languages: languages_conversion_to_controlled_vocab_uri,
      creators: creators,
      subject: subjects,
      created: date_created.to_s,
      description: description,

      # Handle visibility plus embargo logic
      visibility: visibility_conversion_to_controlled_vocab_uri,
      visibility_after_embargo: visibility_after_embargo_conversion_to_controlled_vocab_uri,
      embargo_end_date: embargo_end_date,

      # Handle license vs rights
      license: license_conversion_to_controlled_vocab_uri,
      rights: license == 'license_text' ?  license_text_area : nil,

      # Additional fields
      contributors: contributors,
      spatial_subjects: places,
      temporal_subjects: time_periods,
      # citations of previous publication apparently maps to is_version_of
      is_version_of: citations,
      source: source,
      related_link: related_item
    ).unlock_and_fetch_ldp_object do |unlocked_obj|
      unlocked_obj.add_to_path(member_of_paths['community_id'], member_of_paths['collection_id'])
      unlocked_obj.add_files(map_activestorage_files_as_file_objects)
      unlocked_obj.save!
    end
  end

  private

  # Validations

  # TODO: validate if community/collection ID's are actually in Fedora?
  def communities_and_collections_validations
    return if member_of_paths.blank? # caught by presence check
    # member_of_paths.each do |path| # TODO eventually this will be an array of hashes
    errors.add(:member_of_paths, :community_not_found) if member_of_paths['community_id'].blank?
    errors.add(:member_of_paths, :collection_not_found) if member_of_paths['collection_id'].blank?
    # end
  end

  def validate_describe_item?
    (active? && describe_item?) || validate_choose_license_and_visibility?
  end

  def validate_choose_license_and_visibility?
    (active? && choose_license_and_visibility?) || validate_upload_files?
  end

  def validate_upload_files?
    (active? && upload_files?) || archived?
  end

  def validate_if_license_is_text?
    validate_choose_license_and_visibility? && license_text?
  end

  def validate_if_visibility_is_embargo?
    validate_choose_license_and_visibility? && embargo?
  end

  # Fedora file handling
  # Convert ActiveStorage objects into File objects so we can deposit them into fedora
  def map_activestorage_files_as_file_objects
    files.map do |file|
      # Can ActiveStorage make this easier?
      # Most of this low level file stuff are hidden behind private APIs
      # Perhaps we can do this via `download_blob_to_tempfile` once on rails 5.2
      # https://github.com/rails/rails/blob/master/activestorage/lib/active_storage/downloading.rb#L7
      file_obj = Tempfile.open([file.filename.base, file.filename.extname]) do |temp_file|
        file.download { |chunk| temp_file.write(chunk) }
        temp_file
      end

      # ActiveFedora is weird, it wants a File.open handle or something not a File object
      File.open(file_obj.path, 'r')
    end
  end

  # Control Vocab Conversions

  # Maps Language names to CONTROLLED_VOCABULARIES[:language] URIs
  def languages_conversion_to_controlled_vocab_uri
    languages.pluck(:name).map do |language|
      CONTROLLED_VOCABULARIES[:language].send(language)
    end
  end

  # Maps ItemDraft.licenses to CONTROLLED_VOCABULARIES[:license]
  def license_conversion_to_controlled_vocab_uri
    # no mapping for `license_text` as this gets checked and ingested as a `rights` field in Fedora Item
    return nil if license == 'license_text'

    conversions =
      { attribution_non_commercial: :attribution_noncommercial_4_0_international,
        attribution: :attribution_4_0_international,
        attribution_non_commercial_no_derivatives: :attribution_noncommercial_noderivatives_4_0_international,
        attribution_non_commercial_share_alike: :attribution_noncommercial_sharealike_4_0_international,
        attribution_no_derivatives: :attribution_noderivatives_4_0_international,
        attribution_share_alike: :attribution_sharealike_4_0_international,
        cco_universal: :cc0_1_0_universal,
        public_domain_mark: :public_domain_mark_1_0 }

    code = conversions.fetch(license.to_sym)
    CONTROLLED_VOCABULARIES[:license].send(code)
  end

  # silly stuff needed for handling multivalued publication status attribute when Item type is `Article`
  def handle_publication_status
    if type == :journal_article_draft
      [CONTROLLED_VOCABULARIES[:publication_status].draft, CONTROLLED_VOCABULARIES[:publication_status].submitted]
    elsif type == :journal_article_published
      [CONTROLLED_VOCABULARIES[:publication_status].published]
    end
  end

  # Maps Type names to CONTROLLED_VOCABULARIES[:item_type]
  def item_type_conversion_to_controlled_vocab_uri
    conversions = { book: :book,
                    book_chapter: :chapter,
                    conference_workshop_poster: :conference_poster,
                    conference_workshop_presenation: :conference_paper,
                    dataset: :dataset,
                    image: :image,
                    journal_article_draft: :article,
                    journal_article_published: :article,
                    learning_object: :learning_object,
                    report: :report,
                    research_material: :research_material,
                    review: :review }

    code = conversions.fetch(type.name.to_sym)
    CONTROLLED_VOCABULARIES[:item_type].send(code)
  end

  # Maps ItemDraft.visibilities to CONTROLLED_VOCABULARIES[:visibility]
  def visibility_conversion_to_controlled_vocab_uri
    # Can't have a private or draft visibilty so no mappings for this
    conversions = { open_access: :public,
                    embargo: :embargo,
                    authenticated: :authenticated }

    code = conversions.fetch(visibility.to_sym)
    CONTROLLED_VOCABULARIES[:visibility].send(code)
  end

  # Maps ItemDraft.visibility_after_embargo to CONTROLLED_VOCABULARIES[:visibility]
  def visibility_after_embargo_conversion_to_controlled_vocab_uri
    conversions = { opened: :public,
                    ccid_protected: :authenticated }

    code = conversions.fetch(visibility_after_embargo.to_sym)
    CONTROLLED_VOCABULARIES[:visibility].send(code)
  end

end
