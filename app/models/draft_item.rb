class DraftItem < ApplicationRecord

  enum status: { inactive: 0, active: 1, archived: 2 }

  enum wizard_step: { describe_item: 0,
                      choose_license_and_visibility: 1,
                      upload_files: 2,
                      review_and_deposit_item: 3 }

  enum license: { attribution_non_commercial: 0,
                  attribution: 1,
                  attribution_non_commercial_no_derivatives: 2,
                  attribution_non_commercial_share_alike: 3,
                  attribution_no_derivatives: 4,
                  attribution_share_alike: 5,
                  cco_universal: 6,
                  public_domain_mark: 7,
                  license_text: 8 }
  LICENSE_TO_URI_CODE =
  { attribution_non_commercial: :attribution_noncommercial_4_0_international,
      attribution: :attribution_4_0_international,
      attribution_non_commercial_no_derivatives: :attribution_noncommercial_noderivatives_4_0_international,
      attribution_non_commercial_share_alike: :attribution_noncommercial_sharealike_4_0_international,
      attribution_no_derivatives: :attribution_noderivatives_4_0_international,
      attribution_share_alike: :attribution_sharealike_4_0_international,
      cco_universal: :cc0_1_0_universal,
      public_domain_mark: :public_domain_mark_1_0 }.freeze
  URI_CODE_TO_LICENSE = LICENSE_TO_URI_CODE.invert


  # Can't use public as this is a ActiveRecord method, using open_access instead
  enum visibility: { open_access: 0,
                     embargo: 1,
                     authenticated: 2 }

 VISIBILITY_TO_URI_CODE = { open_access: :public,
                            embargo: :embargo,
                            authenticated: :authenticated }.freeze
  URI_CODE_TO_VISIBILITY = VISIBILITY_TO_URI_CODE.invert

  # Can't reuse same keys as visibility enum above, need to differentiate keys a bit
  #
  # According to requirement's this will not be set from the UI
  # By default it will always be in `public`/`opened` status
  # Only needed for for the odd chance they want to change an item's visibility_after_embargo
  # to `ccid_authenticated`/`authenticated` from the console
  enum visibility_after_embargo: { opened: 0,
                                   ccid_protected: 1 }

 VISIBILITY_AFTER_EMBARGO_TO_URI_CODE = { opened: :public,
                                          ccid_protected: :authenticated }.freeze
 URI_CODE_TO_VISIBILITY_AFTER_EMBARGO = VISIBILITY_AFTER_EMBARGO_TO_URI_CODE.invert


 ITEM_TYPE_TO_URI_CODE = {  book: :book,
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
                       review: :review }.freeze
  URI_CODE_TO_ITEM_TYPE = ITEM_TYPE_TO_URI_CODE.invert

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
  validate :files_are_virus_free, if: :validate_upload_files?

  def communities
    return unless member_of_paths.present? && member_of_paths['community_id']
    member_of_paths['community_id'].map do |cid|
      Community.find(cid)
    end
  end

  def each_community_collection
    return unless member_of_paths && member_of_paths['community_id'].present?
    member_of_paths['community_id'].each_with_index do |community_id, idx|
      collection_id = member_of_paths['collection_id'][idx]
      yield Community.find(community_id), collection_id.present? ? Collection.find(collection_id) : nil
    end
  end

  def thumbnail
    if thumbnail_id.present?
      # TODO: Weird bug with activestorage when walking the assocation to all the attachments
      # Should be able to just do `files.where` or `files.find_by` but what returns
      # is either an Attachment class (expected) or an Enumerator (?).
      # Easier just to get it directly from active storages table instead
      file = ActiveStorage::Attachment.find_by(id: thumbnail_id)
      return file if file.present? # If not present, then fall below and just return first file
    end

    files.first
  end

  def uncompleted_step?(step)
    # Bit confusing here, but when were in an active state, aka draft item has data,
    # the step saved on the object is actually a step behind. As it is only updated on an update for a new step.
    # Hence we just do current step + one to get the actual step here.
    # For an inactive/archived state we are what is expected as we are starting/ending on the same step as what's saved in the object
    if active? && errors.empty?
      DraftItem.wizard_steps[wizard_step] + 1 < DraftItem.wizard_steps[step]
    else
      DraftItem.wizard_steps[wizard_step] < DraftItem.wizard_steps[step]
    end
  end

  def last_completed_step
    # Comment above in `#uncompleted_step?` applies here with regards to the extra logic around active state
    # and getting the next step instead of the current step
    if active?
      DraftItem.wizard_steps.key(DraftItem.wizard_steps.fetch(wizard_step) + 1).to_sym
    else
      wizard_step
    end
  end

  def update_from_fedora_item(item)
    draft_attributes = {
      user_id: item.owner,
      title: item.title,
      alternate_title: item.alternative_title,
      type: item_type_for_uri(item.item_type),
      # publication status
      languages: languages_for_uris(item.languages),

      creators: item.creators,
      subjects: item.subject,
      date_created: DateTime.parse(item.created),
      description: item.description,
      visibility: visibility_for_uri(item.visibility),
      visibility_after_embargo: visibility_after_embargo_for_uri(item.visibility_after_embargo),
      embargo_end_date: item.embargo_end_date,
      license: license_for_uri(item.license),
      license_text_area: item.rights,
      contributors: item.contributors,
      places: item.spatial_subjects,
      time_periods: item.temporal_subjects,
      citations: item.is_version_of,
      source: item.source,
      related_item: item.related_link
    }
    self.assign_attributes(draft_attributes)
    self.member_of_paths = {'community_id' => [], 'collection_id' => []}

    item.each_community_collection do |community, collection|
      self.member_of_paths['community_id'] << community.id
      self.member_of_paths['collection_id'] << collection.id
    end

    # TODO files
    self.save(validate: false)
  end

  def sync_with_fedora
    self.update_from_fedora_item(Item.find(self.uuid))
  end

  def self.from_item(item)
    draft = DraftItem.find_by(uuid: item.id)
    draft ||= DraftItem.new(uuid: item.id)

    draft.update_from_fedora_item(item)
    draft
  end

  # Fedora file handling
  # Convert ActiveStorage objects into File objects so we can deposit them into fedora
  def map_activestorage_files_as_file_objects
    files.map do |file|
      path = file_path_for(file)
      original_filename = file.filename.to_s
      File.open(path) do |f|
        # We're exploiting the fact that Hydra-Works calls original_filename on objects passed to it, if they
        # respond to that method, in preference to looking at the final portion of the file path, which,
        # because we fished this out of ActiveStorage, is just a hash. In this way we present Fedora with the original
        # file name of the object and not a hashed or otherwise modified version temporarily created during ingest
        f.send(:define_singleton_method, :original_filename, ->() { original_filename })
        yield f
      end
    end
  end

  # Control Vocab Conversions

  # Maps Language names to CONTROLLED_VOCABULARIES[:language] URIs
  def languages_as_uri
    languages.pluck(:name).map do |language|
      CONTROLLED_VOCABULARIES[:language].send(language)
    end
  end

  def languages_for_uris(uris)
    uris.map do |uri|
      code = CONTROLLED_VOCABULARIES[:language].from_uri(uri)
      raise ArgumentError, "No known code for language uri: #{uri}" unless code.present?
      language = Language.find_by(name: code)
      raise ArgumentError, "No draft language found for code: #{code}" unless language.present?
      language
    end
  end

  # Maps DraftItem.licenses to CONTROLLED_VOCABULARIES[:license]
  def license_as_uri
    # no mapping for `license_text` as this gets checked and ingested as a `rights` field in Fedora Item
    return nil if license == 'license_text'

    code = LICENSE_TO_URI_CODE.fetch(license.to_sym)
    CONTROLLED_VOCABULARIES[:license].send(code)
  end

  def license_for_uri(uri)
    code = CONTROLLED_VOCABULARIES[:license].from_uri(uri)
    license = URI_CODE_TO_LICENSE[code].to_s
    raise ArgumentError, "Unable to map DraftItem license from URI: #{uri}, code: #{code}" unless license.present?
    license
  end

  # silly stuff needed for handling multivalued publication status attribute when Item type is `Article`
  def publication_status_as_uri
    if type.name == 'journal_article_draft'
      [CONTROLLED_VOCABULARIES[:publication_status].draft, CONTROLLED_VOCABULARIES[:publication_status].submitted]
    elsif type.name == 'journal_article_published'
      [CONTROLLED_VOCABULARIES[:publication_status].published]
    end
  end

  # Maps Type names to CONTROLLED_VOCABULARIES[:item_type]
  def item_type_as_uri
    code = ITEM_TYPE_TO_URI_CODE.fetch(type.name.to_sym)
    CONTROLLED_VOCABULARIES[:item_type].send(code)
  end

  def item_type_for_uri(uri)
    # TODO: publication status
    code = CONTROLLED_VOCABULARIES[:item_type].from_uri(uri)
    name = URI_CODE_TO_ITEM_TYPE[code].to_s
    raise ArgumentError, "Unable to map DraftItem type from URI: #{uri}, code: #{code}" unless name.present?
    type = Type.find_by(name: name)
    raise ArgumentError, "Unable to find DraftItem type: #{name}" unless type.present?
    type
  end

  # Maps DraftItem.visibilities to CONTROLLED_VOCABULARIES[:visibility]
  def visibility_as_uri
    # Can't have a private or draft visibilty so no mappings for this
    code = VISIBILITY_TO_URI_CODE.fetch(visibility.to_sym)
    CONTROLLED_VOCABULARIES[:visibility].send(code)
  end

  def visibility_for_uri(uri)
    code = CONTROLLED_VOCABULARIES[:visibility].from_uri(uri)
    visibility = URI_CODE_TO_VISIBILITY[code].to_s
    raise ArgumentError, "Unable to map DraftItem visbility from URI: #{uri}, code: #{code}" unless visibility.present?
    visibility
  end

  # Maps DraftItem.visibility_after_embargo to CONTROLLED_VOCABULARIES[:visibility]
  def visibility_after_embargo_as_uri
    return nil unless embargo?

    code = VISIBILITY_AFTER_EMBARGO_TO_URI_CODE.fetch(visibility_after_embargo.to_sym)
    CONTROLLED_VOCABULARIES[:visibility].send(code)
  end

  def visibility_after_embargo_for_uri(uri)
    return 0 unless uri.present?
    code = CONTROLLED_VOCABULARIES[:visibility].from_uri(uri)
    visibility = URI_CODE_TO_VISIBILITY_AFTER_EMBARGO[code].to_s
    unless visibility.present?
      raise ArgumentError, "Unable to map DraftItem visbility_after_embargo from URI: #{uri}, code: #{code}"
    end
    visibility
  end

  private

  # Validations

  # TODO: validate if community/collection ID's are actually in Fedora?
  def communities_and_collections_validations
    return if member_of_paths.blank? # caught by presence check
    errors.add(:member_of_paths, :community_not_found) if member_of_paths['community_id'].blank?
    errors.add(:member_of_paths, :collection_not_found) if member_of_paths['collection_id'].blank?
    return unless member_of_paths['community_id'].present? && member_of_paths['collection_id'].present?
    member_of_paths['community_id'].each_with_index do |community_id, idx|
      errors.add(:member_of_paths, :community_not_found) if community_id.blank?
      errors.add(:member_of_paths, :collection_not_found) if member_of_paths['collection_id'][idx].blank?
    end
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

  # HACK: Messing with Rails internals for fun and profit
  # we're accessing the raw ActiveStorage local drive service internals to avoid the overhead of pulling temp files
  # out. This WILL break when we move to Rails 5.2 and the internals change.
  def file_path_for(file)
    ActiveStorage::Blob.service.send(:path_for, file.key)
  end

  def files_are_virus_free
    return unless defined?(Clamby)
    files.each do |file|
      path = file_path_for(file)
      errors.add(:files, :infected, filename: file.filename.to_s) unless Clamby.safe?(path)
    end
  end

end
