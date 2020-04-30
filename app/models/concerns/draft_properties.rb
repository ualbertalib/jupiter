module DraftProperties
  extend ActiveSupport::Concern

  UNIVERSITY_INCEPTION_YEAR = 1908

  included do

    # "status" enum is for keeping track of where a draft object is within the deposit wizard workflow
    # Possible status values are as follows:
    # inactive: Draft objects where the user never passed first step of deposit wizard.
    # active: Draft objects where the user made it passed first step, but hasn't finished completing the deposit wizard.
    # archived: Draft objects that have been "published" where a user has successfully deposited and completed the deposit wizard.
    enum status: { inactive: 0, active: 1, archived: 2 }

    # Note that dependent: false is necessary here as Items and DraftItems can both have ActiveStorage::Attachment records
    # that point at the same underlying blob record. See Item#from_draft.
    has_many_attached :files, dependent: false

    belongs_to :user

    validates :embargo_end_date, presence: true, if: :validate_if_visibility_is_embargo?

    validates :files, presence: true, if: :validate_upload_files?
    validate :files_are_virus_free, if: :validate_upload_files?

    scope :unpublished, -> { where(status: :active).where('uuid IS NULL') }

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
        file = files.find_by(blob_id: thumbnail_id)
        return file if file.present? # If not present, then fall below and just return first file
      end

      files.first
    end

    # compatibility with the thumbnail API used in Items/Theses and Communities
    def thumbnail_path(args = { resize: '100x100', auto_orient: true })
      return nil unless thumbnail.present? && thumbnail.blob.present?

      Rails.application.routes.url_helpers.rails_representation_path(thumbnail.variant(args).processed)
    rescue ActiveStorage::InvariableError
      begin
        Rails.application.routes.url_helpers.rails_representation_path(thumbnail.preview(args).processed)
      rescue ActiveStorage::UnpreviewableError
        nil
      end
    end

    def thumbnail_file
      thumbnail if thumbnail.present? && thumbnail.blob.present?
    end

    def uncompleted_step?(steps, step)
      # Bit confusing here, but when were in an active state, aka draft item has data,
      # the step saved on the object is actually a step behind. As it is only updated on an update for a new step.
      # Hence we just do current step + one to get the actual step here.
      # For an inactive/archived state we are what is expected as we are starting/ending on the same step as what's saved in the object
      if active? && errors.empty?
        steps[wizard_step] + 1 < steps[step]
      else
        steps[wizard_step] < steps[step]
      end
    end

    def last_completed_step
      # Comment above in `#uncompleted_step?` applies here with regards to the extra logic around active state
      # and getting the next step instead of the current step
      if active?
        self.class.wizard_steps.key(self.class.wizard_steps.fetch(wizard_step) + 1).to_sym
      else
        wizard_step
      end
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
          f.send(:define_singleton_method, :original_filename, -> { original_filename })
          yield f
        end
      end
    end

    private

    def communities_and_collections_presence
      return if member_of_paths.blank? # caught by presence check

      errors.add(:member_of_paths, :community_blank) if member_of_paths['community_id'].blank?
      errors.add(:member_of_paths, :collection_blank) if member_of_paths['collection_id'].blank?
    end

    def communities_and_collections_existence
      return if member_of_paths.blank?
      return if member_of_paths['community_id'].blank? || member_of_paths['collection_id'].blank?

      member_of_paths['community_id'].each_with_index do |community_id, idx|
        collection_id = member_of_paths['collection_id'][idx]
        community = Community.find_by(id: community_id)
        errors.add(:member_of_paths, :community_not_found) if community.blank?

        collection = Collection.find_by(id: collection_id)
        if collection.blank?
          errors.add(:member_of_paths, :collection_not_found)
        elsif collection.community_id != community.id
          errors.add(:member_of_paths, :collection_not_in_community)
        end
      end
    end

    def validate_choose_license_and_visibility?
      (active? && choose_license_and_visibility?) || validate_upload_files?
    end

    def validate_upload_files?
      (active? && upload_files?) || archived?
    end

    def validate_if_visibility_is_embargo?
      validate_choose_license_and_visibility? && embargo?
    end

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
end
