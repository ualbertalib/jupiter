# TURN OFF DOIs FOR INITIAL MIGRATION

class Item < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::WorkBehavior

  VISIBILITY_EMBARGO = 'embargo'.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]
  has_attribute :subject, ::RDF::Vocab::DC.subject, solrize_for: [:search, :facet]
  has_attribute :creator, ::RDF::Vocab::DC.creator, solrize_for: [:search, :facet]
  has_attribute :contributor, ::RDF::Vocab::DC.contributor, solrize_for: [:search, :facet]
  has_attribute :description, ::RDF::Vocab::DC.description, type: :text, solrize_for: :search
  has_attribute :publisher, ::RDF::Vocab::DC.publisher, solrize_for: [:search, :facet]
  # has_attribute :date_modified, ::RDF::Vocab::DC.modified, type: :date, solrize_for: :sort
  has_attribute :language, ::RDF::Vocab::DC.language, solrize_for: [:search, :facet]
  has_attribute :doi, ::VOCABULARY[:ualib].doi, solrize_for: :exact_match

  has_multival_attribute :member_of_paths, ::VOCABULARY[:ualib].path,
                         type: :path,
                         solrize_for: :pathing,
                         facet_value_presenter: ->(path) { Item.path_to_titles(path) }

  has_attribute :embargo_end_date, ::RDF::Vocab::DC.modified, type: :date, solrize_for: [:sort]
  # embargo_target_visibility
  # storage only
  # embargo_log as multival
  # fedora3id
  # ingestbatch
  # fedora3handle

  # related object fedora 3 foxml
  # related object old stats
  additional_search_index :doi_without_label, solrize_for: :exact_match,
                                              as: -> { doi.gsub('doi:', '') if doi.present? }

  def self.display_attribute_names
    super - [:member_of_paths]
  end

  # This would be the seam where we may want to introduce a more efficient cache for mapping
  # community_id/collection_id paths to titles, as this is going to get hit a lot on facet results
  # If names were unique, we wouldn't have to do this translation, but c'est la vie
  def self.path_to_titles(path)
    community_id, collection_id = path.split('/')
    community_title = Community.find(community_id).title
    collection_title = if collection_id
                         '/' + Collection.find(collection_id).title
                       else
                         ''
                       end
    community_title + collection_title
  end

  def self.valid_visibilities
    super + [VISIBILITY_EMBARGO]
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

  unlocked do
    validates :embargo_end_date, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
    validates :embargo_end_date, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
    validates :member_of_paths, presence: true
    validates :title, presence: true
    validate :communities_and_collections_validations

    def add_to_path(community_id, collection_id)
      self.member_of_paths += ["#{community_id}/#{collection_id}"]
      # TODO: also add the collection (not the community) to the Item's memberOf relation, as metadata
      # wants to continue to model this relationship in pure PCDM terms, and member_of_path is really for our needs
      # so that we can facet by community and/or collection properly
      # TODO: add collection_id to member_of_collections
    end

    def update_communities_and_collections(communities, collections)
      return unless communities.present? && collections.present?
      self.member_of_paths = communities.map.with_index do |community_id, idx|
        "#{community_id}/#{collections[idx]}"
      end
    end

    def communities_and_collections_validations
      return if member_of_paths.blank?
      member_of_paths.each do |path|
        community_id, collection_id = path.split('/')
        community = Community.find_by(community_id)
        errors.add(:member_of_paths, :community_not_found, id: community_id) if community.blank?
        collection = Collection.find_by(collection_id)
        errors.add(:member_of_paths, :collection_not_found, id: collection_id) if collection.blank?
      end
    end

    def add_communities_and_collections(communities, collections)
      return unless communities.present? && collections.present?
      communities.each_with_index do |community, idx|
        add_to_path(community, collections[idx])
      end
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
          unlocked_fileset.contained_filename = file.original_filename
          unlocked_fileset.save!
          self.members += [unlocked_fileset]
          # pull in hydra derivatives, set temp file base
          # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
        end
      end
    end
  end

end
