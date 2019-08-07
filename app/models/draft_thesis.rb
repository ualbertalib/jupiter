class DraftThesis < ApplicationRecord

  include DraftProperties

  # Metadata team prefers we store and use a number (e.g. '06' or '11')
  # to represent the graduation term (e.g. Spring or Fall)
  # This TERMS constant is used by the graduation term dropdown on the deposit form,
  # mapping the string label to the number value that we wish to use.
  TERMS = [
    [I18n.t('admin.theses.graduation_terms.spring'), '06'],
    [I18n.t('admin.theses.graduation_terms.fall'), '11']
  ].freeze

  enum wizard_step: { describe_thesis: 0,
                      choose_license_and_visibility: 1,
                      upload_files: 2,
                      review_and_deposit_thesis: 3 }

  # Can't use public as this is a ActiveRecord method, using open_access instead
  enum visibility: { open_access: 0,
                     embargo: 1 }

  VISIBILITY_TO_URI_CODE = { open_access: :public,
                             embargo: :embargo }.freeze
  URI_CODE_TO_VISIBILITY = VISIBILITY_TO_URI_CODE.invert

  belongs_to :language, optional: true
  belongs_to :institution, optional: true

  validates :title, :description, :creator,
            :member_of_paths, :graduation_year,
            presence: true, if: :validate_describe_thesis?

  validate :communities_and_collections_presence,
           :communities_and_collections_existence,
           :depositor_can_deposit, if: :validate_describe_thesis?

  validates :rights, :visibility, presence: true, if: :validate_choose_license_and_visibility?

  acts_as_rdfable do |config|
    config.description has_predicate: ::RDF::Vocab::DC.abstract
    config.language_id has_predicate: ::RDF::Vocab::DC.language
    config.date_accepted has_predicate: ::RDF::Vocab::DC.dateAccepted
    config.date_submitted has_predicate: ::RDF::Vocab::DC.dateSubmitted
    config.degree has_predicate: ::RDF::Vocab::BIBO.degree
    config.institution_id has_predicate: ::TERMS[:swrc].institution
    config.creator has_predicate: ::TERMS[:ual].dissertant
    # TODO: add graduation date column
    # config.graduation_date has_predicate: ::TERMS[:ual].graduation_date
    # TODO add
    # config.thesis_level has_predicate: ::TERMS[:ual].thesis_level
    # TODO add
    # config.proquest has_predicate: ::TERMS[:ual].proquest
    # TODO add
    # config.unicorn has_predicate: ::TERMS[:ual].unicorn
    config.specialization has_predicate: ::TERMS[:ual].specialization
    config.departments has_predicate: ::TERMS[:ual].department_list
    config.supervisors has_predicate: ::TERMS[:ual].supervisor_list
    config.committee_members has_predicate: ::TERMS[:ual].committee_member
    config.departments has_predicate: ::TERMS[:ual].department
    config.supervisors has_predicate: ::TERMS[:ual].supervisor
  end

  def update_from_fedora_thesis(thesis, for_user)
    draft_attributes = {
      user_id: for_user.id,
      title: thesis.title,
      alternate_title: thesis.alternative_title,
      language: language_for_uri(thesis.language),
      creator: thesis.dissertant,
      subjects: thesis.subject,
      graduation_term: parse_graduation_term_from_fedora(thesis.graduation_date),
      graduation_year: thesis.sort_year,
      description: thesis.abstract,
      visibility: visibility_for_uri(thesis.visibility),
      embargo_end_date: thesis.embargo_end_date,
      rights: thesis.rights,
      date_accepted: thesis.date_accepted,
      date_submitted: thesis.date_submitted,
      degree: thesis.degree,
      degree_level: thesis.thesis_level,
      institution: institution_for_uri(thesis.institution),
      specialization: thesis.specialization,
      departments: thesis.departments,
      supervisors: thesis.supervisors,
      committee_members: thesis.committee_members
    }
    assign_attributes(draft_attributes)

    # reset paths if the file move in Fedora outside the draft process
    self.member_of_paths = { 'community_id' => [], 'collection_id' => [] }

    thesis.each_community_collection do |community, collection|
      member_of_paths['community_id'] << community.id
      member_of_paths['collection_id'] << collection.id
    end

    save(validate: false)

    # reset files if the files have changed in Fedora outside of the draft process
    # NOTE: destroy the attachment record, DON'T use #purge, which will wipe the underlying blob shared with the
    # published item's shim
    files.each(&:destroy) if thesis.files.present?

    # add an association between the same underlying blobs the Item uses and the Draft
    thesis.files_attachments.each do |attachment|
      ActiveStorage::Attachment.create(record: self, blob: attachment.blob, name: :files)
    end
  end

  # Pull latest data from Fedora if data is more recent than this draft
  # This would happen if, eg) someone manually updated the Fedora record in the Rails console
  # and then someone visited this item's draft URL directly without bouncing through ItemsController#edit
  def sync_with_fedora(for_user:)
    thesis = Thesis.find(uuid)
    update_from_fedora_thesis(thesis, for_user) if thesis.updated_at > updated_at
  end

  def self.from_thesis(thesis, for_user:)
    draft = DraftThesis.find_by(uuid: thesis.id)
    draft ||= DraftThesis.new(uuid: thesis.id)

    draft.update_from_fedora_thesis(thesis, for_user)
    draft
  end

  # Control Vocab Conversions

  # Maps Language name to CONTROLLED_VOCABULARIES[:language] URI
  def language_as_uri
    return nil if language&.name.blank?

    CONTROLLED_VOCABULARIES[:language].send(language.name)
  end

  def language_for_uri(uri)
    return nil if uri.blank?

    code = CONTROLLED_VOCABULARIES[:language].from_uri(uri)
    raise ArgumentError, "No known code for language uri: #{uri}" if code.blank?

    language = Language.find_by(name: code)
    raise ArgumentError, "No draft language found for code: #{code}" if language.blank?

    language
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

  # Maps institution names to CONTROLLED_VOCABULARIES[:institution]
  def institution_as_uri
    return nil if institution&.name.blank?

    CONTROLLED_VOCABULARIES[:institution].send(institution.name)
  end

  def institution_for_uri(uri)
    return nil if uri.blank?

    code = CONTROLLED_VOCABULARIES[:institution].from_uri(uri)
    raise ArgumentError, "No known code for institution uri: #{uri}" if code.blank?

    institution = Institution.find_by(name: code)
    raise ArgumentError, "No draft institution found for code: #{code}" if institution.blank?

    institution
  end

  private

  def parse_graduation_term_from_fedora(graduation_date)
    result = graduation_date&.match(/-(06|11)/)
    result = result[0]&.gsub!('-', '') if result.present?
    result
  end

  def validate_describe_thesis?
    (active? && describe_thesis?) || validate_choose_license_and_visibility?
  end

  # Only an admin user can deposit and only into a restricted collection
  def depositor_can_deposit
    return if member_of_paths.blank?
    return if member_of_paths['community_id'].blank? || member_of_paths['collection_id'].blank?

    member_of_paths['community_id'].each_with_index do |_community_id, idx|
      collection_id = member_of_paths['collection_id'][idx]
      collection = Collection.find_by(collection_id)
      next if collection.blank?
      next if collection.restricted && user.admin?

      errors.add(:member_of_paths, :collection_restricted)
    end
  end

end
