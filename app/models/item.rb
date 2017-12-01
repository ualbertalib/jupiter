
class Item < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::WorkBehavior

  VISIBILITY_EMBARGO = 'embargo'.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze

  # Dublin Core attributes
  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]
  has_multival_attribute :creator, ::RDF::Vocab::DC.creator, solrize_for: [:search, :facet]
  has_multival_attribute :contributor, ::RDF::Vocab::DC.contributor, solrize_for: [:search, :facet]
  has_attribute :created, ::RDF::Vocab::DC.created, solrize_for: [:search, :sort]
  has_attribute :sort_year, ::VOCABULARY[:ual].sortyear, solrize_for: [:search, :sort, :facet]
  has_multival_attribute :subject, ::RDF::Vocab::DC.subject, solrize_for: [:search, :facet]
  has_attribute :description, ::RDF::Vocab::DC.description, type: :text, solrize_for: :search
  has_attribute :publisher, ::RDF::Vocab::DC.publisher, solrize_for: [:search, :facet]
  # has_attribute :date_modified, ::RDF::Vocab::DC.modified, type: :date, solrize_for: :sort
  has_multival_attribute :language, ::RDF::Vocab::DC.language,
                         solrize_for: [:search, :facet]
  has_attribute :embargo_end_date, ::RDF::Vocab::DC.modified, type: :date, solrize_for: [:sort]
  has_attribute :license, ::RDF::Vocab::DC.license, solrize_for: [:search]

  # UAL attributes
  has_attribute :depositor, ::VOCABULARY[:ual].depositor, solrize_for: [:search]
  has_attribute :fedora3_handle, ::VOCABULARY[:ual].fedora3handle, solrize_for: :exact_match
  has_attribute :fedora3_uuid, ::VOCABULARY[:ual].fedora3uuid, solrize_for: :exact_match
  has_attribute :ingest_batch, ::VOCABULARY[:ual].ingestbatch, solrize_for: :exact_match
  has_multival_attribute :member_of_paths, ::VOCABULARY[:ual].path,
                         type: :path,
                         solrize_for: :pathing

  # Prism attributes
  has_attribute :doi, ::VOCABULARY[:prism].doi, solrize_for: :exact_match

  # Solr only
  additional_search_index :doi_without_label, solrize_for: :exact_match,
                                              as: -> { doi.gsub('doi:', '') if doi.present? }

  def self.display_attribute_names
    super - [:member_of_paths]
  end

  def self.valid_visibilities
    super + [VISIBILITY_EMBARGO]
  end

  def self.license_text(license_uri)
    CONTROLLED_VOCABULARIES[:license].each do |lic|
      if lic[:uri] == license_uri
        return I18n.t("controlled_vocabularies.license.#{lic[:code]}")
      end
    end
    raise ApplicationError("License not found for #{license_uri}")
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

  # TODO: implement me
  def thumbnail
    nil
  end

  unlocked do
    validates :embargo_end_date, presence: true, if: ->(item) { item.visibility == VISIBILITY_EMBARGO }
    validates :embargo_end_date, absence: true, if: ->(item) { item.visibility != VISIBILITY_EMBARGO }
    validates :member_of_paths, presence: true
    validates :title, presence: true
    validates :language, presence: true
    validates :license, presence: true
    validate :communities_and_collections_validations
    validate :language_validations
    validate :license_validations

    before_validation do
      # TODO: for theses, the sort_year attribute should be derived from ual:graduationDate
      self.sort_year = Date.parse(created).year.to_s if created.present?
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
          unlocked_fileset.save!
          self.members += [unlocked_fileset]
          # pull in hydra derivatives, set temp file base
          # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
        end
      end
    end

    def language_validations
      uris = ::CONTROLLED_VOCABULARIES[:language].map { |lang| lang[:uri] }
      language.each do |lang|
        errors.add(:language, :not_recognized) unless uris.include?(lang)
      end
    end

    def license_validations
      return if ::CONTROLLED_VOCABULARIES[:license].any? { |lic| lic[:uri] == license }
      errors.add(:license, :not_recognized)
    end
  end

end
