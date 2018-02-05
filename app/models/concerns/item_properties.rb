
module ItemProperties
  extend ActiveSupport::Concern

  VISIBILITY_EMBARGO = CONTROLLED_VOCABULARIES[:visibility].embargo.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze
  VISIBILITIES_AFTER_EMBARGO = [CONTROLLED_VOCABULARIES[:visibility].authenticated,
                                CONTROLLED_VOCABULARIES[:visibility].draft,
                                CONTROLLED_VOCABULARIES[:visibility].public].freeze

  included do
    # Dublin Core attributes
    has_attribute :alternative_title, ::RDF::Vocab::DC.alternative, solrize_for: :search
    # `sort_year` is faceted differently for `Item` and `Thesis`
    has_attribute :sort_year, ::TERMS[:ual].sortyear, solrize_for: [:search, :sort, :facet]
    # `subject` is validated differently for `Item` and `Thesis`
    has_multival_attribute :subject, ::RDF::Vocab::DC11.subject, solrize_for: [:search, :facet]
    has_multival_attribute :is_version_of, ::RDF::Vocab::DC.isVersionOf, solrize_for: :exact_match

    # UAL attributes
    has_attribute :fedora3_handle, ::TERMS[:ual].fedora3handle, solrize_for: :exact_match
    has_attribute :ingest_batch, ::TERMS[:ual].ingestbatch, solrize_for: :exact_match
    has_multival_attribute :member_of_paths, ::TERMS[:ual].path,
                           type: :path,
                           solrize_for: :pathing

    # Prism attributes
    has_attribute :doi, ::TERMS[:prism].doi, solrize_for: :exact_match
    # `rights` is validated differently for `Item` and `Thesis`
    has_attribute :rights, ::RDF::Vocab::DC11.rights, solrize_for: :exact_match

    has_attribute :embargo_end_date, ::RDF::Vocab::DC.available, type: :date, solrize_for: [:sort]

    has_multival_attribute :embargo_history, ::TERMS[:acl].embargoHistory, solrize_for: :exact_match
    has_attribute :visibility_after_embargo, ::TERMS[:acl].visibilityAfterEmbargo, solrize_for: :exact_match

    # Solr only
    additional_search_index :doi_without_label, solrize_for: :exact_match,
                                                as: -> { doi.gsub('doi:', '') if doi.present? }

    unlocked do
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
          fs.unlock_and_fetch_ldp_object do |unlocked_fs|
            unlocked_fs.delete
          end
        end

        self.ordered_members = []
      end

      def add_files(files)
        return if files.blank?
        # Need a item id for file sets to point to
        # TODO should this be a side effect? should we throw an exception if there's no id? Food for thought
        save! if id.nil?

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
            unlocked_fileset.sitemap_link = "<rs:ln \
href=\"#{Rails.application.routes.url_helpers.url_for(controller: :file_sets,
                                                      action: :download,
                                                      id: unlocked_fileset.id,
                                                      file_name: unlocked_fileset.contained_filename,
                                                      only_path: true)}\" \
rel=\"content\" \
hash=\"#{unlocked_fileset.original_file.checksum.algorithm.downcase}:"\
"#{unlocked_fileset.original_file.checksum.value}\" \
length=\"#{unlocked_fileset.original_file.size}\" \
type=\"#{unlocked_fileset.original_file.mime_type}\"\
/>"
            unlocked_fileset.save!

            self.ordered_members += [unlocked_fileset]
            if Rails.configuration.run_fits_characterization
              Hydra::Works::CharacterizationService.run(unlocked_fileset.original_file)
            end
          end
        end
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

  def thumbnail_fileset(fileset)
    raise ArgumentError, 'Thumbnail must belong to the item it is set for' unless id == fileset.owning_item.id
    thumbnail.purge if thumbnail.present?
    fileset.unlock_and_fetch_ldp_object do |unlocked_fileset|
      unlocked_fileset.create_derivatives
      # Some kinds of things don't get thumbnailed by HydraWorks, eg) .txt files
      return unless unlocked_fileset.thumbnail.present?
      # don't ask. RDF::URIs aren't real Ruby URIs for reasons that presumably made sense to someone, somewhere
      uri = URI.parse(unlocked_fileset.thumbnail.uri.to_s)
      uri.open do |uri_data|
        thumbnail.attach(io: uri_data,
                         filename: "#{unlocked_fileset.contained_filename}.jpg",
                         content_type: 'image/jpeg')
      end
    end
  end
end
