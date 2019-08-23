class AfThesis < JupiterCore::LockedLdpObject

  has_solr_exporter Exporters::Solr::ThesisExporter

  include ObjectProperties
  include ItemProperties
  include GlobalID::Identification
  ldp_object_includes Hydra::Works::WorkBehavior

  # Dublin Core attributes
  has_attribute :abstract, ::RDF::Vocab::DC.abstract
  # Note: language is single-valued for Thesis, but languages is multi-valued for Item
  # See below for faceting
  has_attribute :language, ::RDF::Vocab::DC.language
  has_attribute :date_accepted, ::RDF::Vocab::DC.dateAccepted
  has_attribute :date_submitted, ::RDF::Vocab::DC.dateSubmitted

  # BIBO
  has_attribute :degree, ::RDF::Vocab::BIBO.degree

  # SWRC
  has_attribute :institution, TERMS[:swrc].institution

  # UAL attributes
  # This one is faceted in `all_contributors`, along with the Item creators/contributors
  has_attribute :dissertant, TERMS[:ual].dissertant
  has_attribute :graduation_date, TERMS[:ual].graduation_date
  has_attribute :thesis_level, TERMS[:ual].thesis_level
  has_attribute :proquest, TERMS[:ual].proquest
  has_attribute :unicorn, TERMS[:ual].unicorn

  has_attribute :specialization, TERMS[:ual].specialization
  has_attribute :departments, TERMS[:ual].department_list
  has_attribute :supervisors, TERMS[:ual].supervisor_list
  has_multival_attribute :committee_members, TERMS[:ual].committee_member
  has_multival_attribute :unordered_departments, TERMS[:ual].department
  has_multival_attribute :unordered_supervisors, TERMS[:ual].supervisor

  # Present a consistent interface with Item#item_type_with_status_code
  def item_type_with_status_code
    :thesis
  end

  def self.from_draft(draft_thesis)
    thesis = Thesis.find(draft_thesis.uuid) if draft_thesis.uuid.present?
    thesis ||= Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_obj|
      unlocked_obj.owner = draft_thesis.user_id if unlocked_obj.owner.blank?
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

      # remove old filesets and attachments and recreate
      unlocked_obj.purge_filesets

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

  def self.from_thesis(thesis)
    raise ArgumentError, "Thesis #{id} already migrated to ActiveRecord" if ArThesis.find_by(id: thesis.id) != nil

    ar_thesis = ArThesis.new(id: thesis.id)

    # this is named differently in ActiveFedora
    ar_thesis.owner_id = thesis.owner
    ar_thesis.aasm_state = thesis.doi_state.aasm_state

    attributes = ar_thesis.attributes.keys.reject do |k|
      ['owner_id', 'created_at', 'updated_at', 'logo_id', 'aasm_state'].include?(k)
    end

    attributes.each do |attr|
      ar_thesis.send("#{attr}=", thesis.send(attr))
    end

    # unconditionally save. If something doesn't pass validations in ActiveFedora, it still needs to come here
    ar_thesis.save(validate: false)

    # add an association between the same underlying blobs the Thesis uses and the new ActiveRecord version
    thesis.files_attachments.each do |attachment|
      new_attachment = ActiveStorage::Attachment.create(record: ar_thesis, blob: attachment.blob, name: :files,
                                                        fileset_uuid: attachment.fileset_uuid)
      # because of the uuid id column, the record_id on new_attachment (currently of type integer), is broken
      # but that's ok. we're going to fix that with this data
      new_attachment.upcoming_record_id = ar_thesis.id
      new_attachment.save!
      if attachment.id == thesis.files_attachment_shim.logo_id
        ar_thesis.logo_id = new_attachment.id
        ar_thesis.save!
      end
    end
    ar_thesis
  end

  unlocked do
    before_save :copy_departments_to_unordered_predicate
    before_save :copy_supervisors_to_unordered_predicate

    validates :dissertant, presence: true
    validates :graduation_date, presence: true
    validates :sort_year, presence: true
    validates :language, uri: { in_vocabulary: :language }
    validates :institution, uri: { in_vocabulary: :institution }

    type [::Hydra::PCDM::Vocab::PCDMTerms.Object, ::RDF::Vocab::BIBO.Thesis]

    before_validation do
      # Note: for Item, the sort_year attribute is derived from dcterms:created
      begin
        self.sort_year = Date.parse(graduation_date).year.to_i if graduation_date.present?
      rescue ArgumentError
        # date was unparsable, try to pull out the first 4 digit number as a year
        capture = graduation_date.scan(/\d{4}/)
        self.sort_year = capture[0].to_i if capture.present?
      end

      def copy_departments_to_unordered_predicate
        return unless departments_changed?

        self.unordered_departments = []
        departments.each { |d| self.unordered_departments += [d] }
      end

      def copy_supervisors_to_unordered_predicate
        return unless supervisors_changed?

        self.unordered_supervisors = []
        supervisors.each { |s| self.unordered_supervisors += [s] }
      end
    end
  end

end
