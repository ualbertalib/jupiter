class DraftThesis < ApplicationRecord

  include DraftProperties

  DEFAULT_RIGHTS = 'This thesis is made available by the University of Alberta Libraries'\
  ' with permission of the copyright owner solely for non-commercial purposes.'\
  ' This thesis, or any portion thereof, may not otherwise be copied or reproduced'\
  ' without the written consent of the copyright owner, except to the extent'\
  ' permitted by Canadian copyright law.'.freeze

  TERMS = ['Spring', 'Fall'].freeze

  # Can't use public as this is a ActiveRecord method, using open_access instead
  enum visibility: { open_access: 0,
                     embargo: 1 }

  VISIBILITY_TO_URI_CODE = { open_access: :public,
                             embargo: :embargo }.freeze
  URI_CODE_TO_VISIBILITY = VISIBILITY_TO_URI_CODE.invert

  belongs_to :language, optional: true

  validates :title, :description, :creator,
            :member_of_paths, :graduation_term, :graduation_year,
            presence: true, if: :validate_describe_item?

  validate :communities_and_collections_presence,
           :communities_and_collections_existence,
           :depositor_can_deposit, if: :validate_describe_item?

  validates :rights, :visibility, presence: true, if: :validate_choose_license_and_visibility?

  def update_from_fedora_thesis(thesis, for_user)
    draft_attributes = {
      user_id: for_user.id,
      title: thesis.title,
      alternate_title: thesis.alternative_title,
      language: language_for_uri(thesis.language),
      dissertant: thesis.creator,
      subjects: thesis.subject,
      graduation_date: "#{graduation_term} #{graduation_year}",
      abstract: thesis.description,
      visibility: visibility_for_uri(thesis.visibility),
      embargo_end_date: thesis.embargo_end_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public,
      rights: DEFAULT_RIGHTS,
      date_accepted: thesis.date_accepted,
      date_submitted: thesis.date_submitted,
      degree: thesis.degree,
      degree_level: thesis.degree_level,
      institution: thesis.institution,
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
    files.purge if thesis.file_sets.present?
    thesis.file_sets.each do |fileset|
      fileset.unlock_and_fetch_ldp_object do |ufs|
        ufs.fetch_raw_original_file_data do |content_type, io|
          files.attach(io: io, filename: ufs.contained_filename, content_type: content_type)
        end
      end
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
    CONTROLLED_VOCABULARIES[:language].send(language.name)
  end

  def language_for_uri(uri)
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

  private

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
