
module ItemProperties
  extend ActiveSupport::Concern

  VISIBILITY_EMBARGO = CONTROLLED_VOCABULARIES[:visibility].embargo.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze
  VISIBILITIES_AFTER_EMBARGO = [CONTROLLED_VOCABULARIES[:visibility].authenticated,
                                CONTROLLED_VOCABULARIES[:visibility].draft,
                                CONTROLLED_VOCABULARIES[:visibility].public].freeze

  included do
    has_attribute :alternative_title, ::RDF::Vocab::DC.alternative, solrize_for: :search
    has_attribute :doi, ::TERMS[:prism].doi, solrize_for: :exact_match
    has_attribute :embargo_end_date, ::RDF::Vocab::DC.available, type: :date, solrize_for: [:sort]
    has_attribute :fedora3_handle, ::TERMS[:ual].fedora3_handle, solrize_for: :exact_match
    has_attribute :ingest_batch, ::TERMS[:ual].ingest_batch, solrize_for: :exact_match
    has_attribute :northern_north_america_filename,
                  ::TERMS[:ual].northern_north_america_filename, solrize_for: :exact_match
    has_attribute :northern_north_america_item_id,
                  ::TERMS[:ual].northern_north_america_item_id, solrize_for: :exact_match
    has_attribute :rights, ::RDF::Vocab::DC11.rights, solrize_for: :exact_match
    has_attribute :sort_year, ::TERMS[:ual].sort_year, type: :integer, solrize_for: [:search, :sort, :range_facet]
    has_attribute :visibility_after_embargo, ::TERMS[:acl].visibility_after_embargo, solrize_for: :exact_match

    has_multival_attribute :embargo_history, ::TERMS[:acl].embargo_history, solrize_for: :exact_match
    has_multival_attribute :is_version_of, ::RDF::Vocab::DC.isVersionOf, solrize_for: :exact_match
    has_multival_attribute :member_of_paths, ::TERMS[:ual].path, type: :path, solrize_for: :pathing

    # See `all_subjects` in including class for faceting
    has_multival_attribute :subject, ::RDF::Vocab::DC11.subject, solrize_for: :search

    additional_search_index :doi_without_label, solrize_for: :exact_match,
                                                as: -> { doi.gsub('doi:', '') if doi.present? }

    attr_accessor :skip_handle_doi_states

    # allow for a uniform way of accessing this information across regular items and theses
    def authors
      respond_to?(:creators) ? creators : [dissertant]
    end

    def creation_date
      respond_to?(:created) ? created : graduation_date
    end

    def doi_state
      @state ||= ItemDoiState.find_or_create_by!(item_id: id) do |state|
        state.aasm_state = (doi.present? ? :available : :not_available)
      end
    end

    unlocked do
      before_save :handle_doi_states
      after_create :handle_doi_states
      before_destroy :remove_doi
      after_destroy :purge_thumbnail, :delete_doi_state, :purge_files

      # If you're looking for rights and subject validations, note that they have separate implementations
      # on the Thesis and Item classes.
      validates :embargo_end_date, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
      validates :embargo_end_date, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
      validates :visibility_after_embargo, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
      validates :visibility_after_embargo, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
      validates :member_of_paths, presence: true
      validate :communities_and_collections_must_exist
      validate :visibility_after_embargo_must_be_valid

      def communities_and_collections_must_exist
        return if member_of_paths.blank?
        member_of_paths.each do |path|
          community_id, collection_id = path.split('/')
          community = Community.find_by(community_id)
          errors.add(:member_of_paths, :community_not_found, id: community_id) if community.blank?
          collection = Collection.find_by(collection_id)
          errors.add(:member_of_paths, :collection_not_found, id: collection_id) if collection.blank?
        end
      end

      def visibility_after_embargo_must_be_valid
        return if visibility_after_embargo.nil?
        return if VISIBILITIES_AFTER_EMBARGO.include?(visibility_after_embargo)
        errors.add(:visibility_after_embargo, :not_recognized)
      end

      before_save do
        if member_of_paths_changed?
          # This adds the `pcdm::memberOf` predicates, pointing to each collection
          self.member_of_collections = []
          member_of_paths.each do |path|
            _community_id, collection_id = path.split('/')
            collection = Collection.find_by(collection_id)

            # This sets `memberOf`
            # TODO: can this be streamlined so that a fetch from Fedora isn't needed?
            collection.unlock_and_fetch_ldp_object do |unlocked_collection|
              self.member_of_collections += [unlocked_collection]
            end
          end
        end
      end

      def handle_doi_states
        # this should be disabled during migration runs and enabled for production
        return unless Rails.application.secrets.doi_minting_enabled

        return if id.blank?

        # ActiveFedora doesn't have skip_callbacks built in? So handle this ourselves.
        # Allow this logic to be skipped if skip_handle_doi_states is set.
        # This is mainly used so we can rollback the state when a job fails and
        # we do not wish to rerun all this logic again which would queue up the same job again
        return (self.skip_handle_doi_states = false) if skip_handle_doi_states.present?

        if doi.blank? # Never been minted before
          doi_state.created!(id) if !private? && doi_state.not_available?
        elsif (doi_state.not_available? && transitioned_from_private?) ||
              (doi_state.available? && (doi_state.doi_fields_changed?(self) || transitioned_to_private?))
          # If private, we only care if visibility has been made public
          # If public, we care if visibility changed to private or doi fields have been changed
          doi_state.altered!(id)
        end
      end

      def remove_doi
        doi_state.removed! if doi.present? && (doi_state.available? || doi_state.not_available?)
      end

      def purge_thumbnail
        thumbnail.purge if thumbnail.present?
      end

      def delete_doi_state
        doi_state.destroy!
      end

      # for use when deleting items for later re-migration, to avoid tombstoning
      # manually updates the underlying aasm_state to preclude running the Withdrawl job
      # rubocop:disable Rails/SkipsModelValidations
      def doi_safe_destroy!
        doi_state.update_attribute(:aasm_state, 'excluded')
        destroy!
      end
      # rubocop:enable Rails/SkipsModelValidations

      def add_to_path(community_id, collection_id)
        self.member_of_paths += ["#{community_id}/#{collection_id}"]
        # TODO: also add the collection (not the community) to the Item's memberOf relation, as metadata
        # wants to continue to model this relationship in pure PCDM terms, and member_of_path is really for our needs
        # so that we can facet by community and/or collection properly
        # TODO: add collection_id to member_of_collections
      end

      def add_communities_and_collections(communities, collections)
        return unless communities.present? && collections.present?
        communities.each_with_index do |community, idx|
          add_to_path(community, collections[idx])
        end
      end

      def purge_files
        FileSet.where(item: id).each do |fs|
          success = fs.unlock_and_fetch_ldp_object(&:delete)
          Rollbar.warn("Couldn't purge fileset #{fs.id} with item id #{id}") unless success
        end

        self.ordered_members = [] unless destroyed?
      end

      def add_files(files)
        return if files.blank?
        # Need a item id for file sets to point to
        # TODO should this be a side effect? should we throw an exception if there's no id? Food for thought
        save! if id.nil?

        # The current and added filesets approach (rather than direct array append) works around bugs in ActiveFedora
        current_filesets = ordered_members || []
        added_filesets = []

        files.each do |file|
          FileSet.new_locked_ldp_object.unlock_and_fetch_ldp_object do |unlocked_fileset|
            unlocked_fileset.owner = owner
            unlocked_fileset.visibility = visibility
            Hydra::Works::AddFileToFileSet.call(unlocked_fileset, file, :original_file,
                                                update_existing: false, versioning: false)
            unlocked_fileset.member_of_collections += [self]
            # Temporarily cache the file name for storing in Solr
            # if the file was uploaded, it responds to +original_filename+
            # if it's a Ruby File object, it has a +basename+. This distinction seems arbitrary.
            unlocked_fileset.contained_filename = if file.respond_to?(:original_filename)
                                                    file.original_filename
                                                  else
                                                    File.basename(file)
                                                  end
            # Store file properties in the format required by the sitemap
            # for quick and easy retrieval -- nobody wants to wait 36hrs for this!
            escaped_path = CGI.escape_html(
              Rails.application.routes.url_helpers.url_for(controller: :file_sets,
                                                           action: :show,
                                                           id: id,
                                                           file_set_id: unlocked_fileset.id,
                                                           file_name: unlocked_fileset.contained_filename,
                                                           only_path: true)
            )
            unlocked_fileset.sitemap_link = "<rs:ln \
href=\"#{escaped_path}\" \
rel=\"content\" \
hash=\"#{unlocked_fileset.original_file.checksum.algorithm.downcase}:"\
"#{unlocked_fileset.original_file.checksum.value}\" \
length=\"#{unlocked_fileset.original_file.size}\" \
type=\"#{unlocked_fileset.original_file.mime_type}\"\
/>"
            unlocked_fileset.save!

            added_filesets << unlocked_fileset
            if Rails.configuration.run_fits_characterization
              Hydra::Works::CharacterizationService.run(unlocked_fileset.original_file)
              unlocked_fileset.original_file.save
            end
          end
        end
        self.ordered_members = current_filesets + added_filesets
        save!
      end
    end
  end

  class_methods do
    def display_attribute_names
      super - [:member_of_paths]
    end

    def valid_visibilities
      super + [VISIBILITY_EMBARGO]
    end

    def public
      where(visibility: JupiterCore::VISIBILITY_PUBLIC)
    end
  end

  def doi_url
    "https://doi.org/#{read_solr_index(:doi_without_label).first}"
  end

  def file_sets
    FileSet.where(item: id)
  end

  def each_community_collection
    member_of_paths.each do |path|
      community_id, collection_id = path.split('/')
      yield Community.find(community_id), Collection.find(collection_id)
    end
  end

  def thumbnail
    @thumbnail ||= ActiveStorage::Attached::One.new(:thumbnail, self)
  end

  # Thumbnailing errors can manifest themselves in a few different ways, so we're trapping this without a specific
  # class.
  def thumbnail_fileset(fileset)
    raise ArgumentError, 'Thumbnail must belong to the item it is set for' unless id == fileset.owning_item.id
    thumbnail.purge if thumbnail.present?
    fileset.unlock_and_fetch_ldp_object do |unlocked_fileset|
      # rubocop:disable Lint/RescueWithoutErrorClass
      begin
        unlocked_fileset.create_derivatives
      rescue => e
        # sometimes soffice crashes when trying to derive certain kinds of files. So we clear out any garbage
        # and leave it unthumbnailed and push the error to Rollbar for further inspection
        Rollbar.error(e)
        thumbnail.purge if thumbnail.present?
        break
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
      # Some kinds of things don't get thumbnailed by HydraWorks, eg) .txt files
      break if unlocked_fileset.thumbnail.blank?
      unlocked_fileset.fetch_raw_thumbnail_data do |content_type, io|
        thumbnail.attach(io: io, filename: "#{unlocked_fileset.contained_filename}.jpg", content_type: content_type)
      end
    end
  end
end
