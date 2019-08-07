class DraftItem < ApplicationRecord

  include DraftProperties

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
                  license_text: 8,
                  unselected: 9 }
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

  ITEM_TYPE_TO_URI_CODE = { book: :book,
                            book_chapter: :chapter,
                            conference_workshop_poster: :conference_workshop_poster,
                            conference_workshop_presentation: :conference_workshop_presentation,
                            dataset: :dataset,
                            image: :image,
                            journal_article_draft: :article,
                            journal_article_published: :article,
                            learning_object: :learning_object,
                            report: :report,
                            research_material: :research_material,
                            review: :review }.freeze
  URI_CODE_TO_ITEM_TYPE = ITEM_TYPE_TO_URI_CODE.invert

  # Rails 5 turns presence check on by default for belongs_to relationships
  belongs_to :type, optional: true

  has_many :draft_items_languages, dependent: :destroy
  has_many :languages, through: :draft_items_languages

  before_validation :strip_input_fields

  validates :title, :type, :languages,
            :creators, :subjects, :date_created,
            :member_of_paths,
            presence: true, if: :validate_describe_item?

  validate :communities_and_collections_presence,
           :communities_and_collections_existence,
           :depositor_can_deposit, if: :validate_describe_item?

  validates :license, :visibility, presence: true, if: :validate_choose_license_and_visibility?
  validates :license_text_area, presence: true, if: :validate_if_license_is_text?
  validate :license_not_unselected, if: :validate_choose_license_and_visibility?

  acts_as_rdfable do |config|
    config.title has_predicate: ::RDF::Vocab::DC.title
    config.creators has_predicate: RDF::Vocab::BIBO.authorList
    config.contributors has_predicate: ::RDF::Vocab::DC11.contributor
    config.date_created has_predicate: ::RDF::Vocab::DC.created
    config.time_periods has_predicate: ::RDF::Vocab::DC.temporal
    config.places has_predicate: ::RDF::Vocab::DC.spatial
    config.description has_predicate: ::RDF::Vocab::DC.description
    # TODO: add
    # config.publisher has_predicate: ::RDF::Vocab::DC.publisher
    # TODO join table
    # config.languages has_predicate: ::RDF::Vocab::DC.language
    config.license has_predicate: ::RDF::Vocab::DC.license
    config.type_id has_predicate: ::RDF::Vocab::DC.type
    config.source has_predicate: ::RDF::Vocab::DC.source
    config.related_item has_predicate: ::RDF::Vocab::DC.relation
    config.status has_predicate: ::RDF::Vocab::BIBO.status
  end

  # rubocop:disable Rails/TimeZone
  def update_from_fedora_item(item, for_user)
    # I suspect this will become some kind of string field, but for now, using UTC
    # HACK: temporarily falling back to a parsable date when editing unparsable data to fix a crasher in Prod,
    # but this needs a longer term fix to accomodate all the messy Date-ish production data
    created_at = begin
      DateTime.parse(item.created)
    rescue ArgumentError
      capture = item.created.scan(/\d{4}/)
      if capture.present?
        Date.parse("1/1/#{capture[0]}")
      else
        Date.parse("1/1/#{Date.current.year}")
      end
    end
    draft_attributes = {
      user_id: for_user.id,
      title: item.title,
      alternate_title: item.alternative_title,
      type: item_type_for_uri(item.item_type, status: item.publication_status),
      languages: languages_for_uris(item.languages),
      creators: item.creators,
      subjects: item.subject,
      date_created: created_at,
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
    assign_attributes(draft_attributes)

    # reset paths if the file move in Fedora outside the draft process
    self.member_of_paths = { 'community_id' => [], 'collection_id' => [] }

    item.each_community_collection do |community, collection|
      member_of_paths['community_id'] << community.id
      member_of_paths['collection_id'] << collection.id
    end

    save(validate: false)

    # reset files if the files have changed in Fedora outside of the draft process
    # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
    # published item's shim
    files.each(&:destroy) if item.files.present?

    # add an association between the same underlying blobs the Item uses and the Draft
    item.files_attachments.each do |attachment|
      ActiveStorage::Attachment.create(record: self, blob: attachment.blob, name: :files)
    end
  end

  # Pull latest data from Fedora if data is more recent than this draft
  # This would happen if, eg) someone manually updated the Fedora record in the Rails console
  # and then someone visited this item's draft URL directly without bouncing through ItemsController#edit
  def sync_with_fedora(for_user:)
    item = Item.find(uuid)
    update_from_fedora_item(item, for_user) if item.updated_at > updated_at
  end

  def self.from_item(item, for_user:)
    draft = DraftItem.find_by(uuid: item.id)
    draft ||= DraftItem.new(uuid: item.id)

    draft.update_from_fedora_item(item, for_user)
    draft
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
      raise ArgumentError, "No known code for language uri: #{uri}" if code.blank?

      language = Language.find_by(name: code)
      raise ArgumentError, "No draft language found for code: #{code}" if language.blank?

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
    return 'license_text' if uri.nil?

    code = CONTROLLED_VOCABULARIES[:license].from_uri(uri)
    license = URI_CODE_TO_LICENSE[code].to_s

    license.presence || 'unselected'
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

  def item_type_for_uri(uri, status:)
    code = CONTROLLED_VOCABULARIES[:item_type].from_uri(uri)
    if status.present?
      if status.include?(CONTROLLED_VOCABULARIES[:publication_status].draft)
        name = 'journal_article_draft'
      elsif status.include?(CONTROLLED_VOCABULARIES[:publication_status].published)
        name = 'journal_article_published'
      else
        raise ArgumentError, "Unmappable DraftItem publication status(es): #{publication_status}"
      end
    else
      name = URI_CODE_TO_ITEM_TYPE[code].to_s
    end

    raise ArgumentError, "Unable to map DraftItem type from URI: #{uri}, code: #{code}" if name.blank?

    type = Type.find_by(name: name)
    raise ArgumentError, "Unable to find DraftItem type: #{name}" if type.blank?

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
    raise ArgumentError, "Unable to map DraftItem visbility from URI: #{uri}, code: #{code}" if visibility.blank?

    visibility
  end

  # Maps DraftItem.visibility_after_embargo to CONTROLLED_VOCABULARIES[:visibility]
  def visibility_after_embargo_as_uri
    return nil unless embargo?

    code = VISIBILITY_AFTER_EMBARGO_TO_URI_CODE.fetch(visibility_after_embargo.to_sym)
    CONTROLLED_VOCABULARIES[:visibility].send(code)
  end

  def visibility_after_embargo_for_uri(uri)
    return 0 if uri.blank?

    code = CONTROLLED_VOCABULARIES[:visibility].from_uri(uri)
    visibility = URI_CODE_TO_VISIBILITY_AFTER_EMBARGO[code].to_s
    if visibility.blank?
      raise ArgumentError, "Unable to map DraftItem visbility_after_embargo from URI: #{uri}, code: #{code}"
    end

    visibility
  end

  private

  # Validations

  def depositor_can_deposit
    return if member_of_paths.blank?
    return if member_of_paths['community_id'].blank? || member_of_paths['collection_id'].blank?

    member_of_paths['community_id'].each_with_index do |_community_id, idx|
      collection_id = member_of_paths['collection_id'][idx]
      collection = Collection.find_by(collection_id)
      next if collection.blank?

      errors.add(:member_of_paths, :collection_restricted) if collection.restricted && !user.admin?
    end
  end

  def validate_describe_item?
    (active? && describe_item?) || validate_choose_license_and_visibility?
  end

  def validate_if_license_is_text?
    validate_choose_license_and_visibility? && license_text?
  end

  def license_not_unselected
    errors.add(:license, :missing) if license == 'unselected'
  end

  def strip_input_fields
    attributes.each do |key, value|
      self[key] = value.reject(&:blank?) if value.is_a?(Array)
      self[key] = nil if self[key].blank?
    end
  end

end
