class Community < JupiterCore::LockedLdpObject

  include ObjectProperties
  # Needed for ActiveStorage (logo)...
  include GlobalID::Identification

  ldp_object_includes Hydra::PCDM::ObjectBehavior

  has_solr_exporter Exporters::Solr::CommunityExporter

  has_attribute :description, ::RDF::Vocab::DC.description, solrize_for: [:search]
  has_multival_attribute :creators, ::RDF::Vocab::DC.creator, solrize_for: :exact_match

  has_one_attached :logo

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where(community_id: id)
  end

  # A virtual attribute to handle removing logos on forms ...
  def remove_logo
    # Never want the checkbox checked by default
    false
  end

  def remove_logo=(val)
    return unless logo.attached? && (val == 'true')

    # This should probably be 'purge_later', but then we have problems on page reload
    logo_attachment.purge
  end

  # compatibility with item thumbnail API
  def thumbnail_url(args = { resize: '100x100', auto_orient: true })
    return nil if logo_attachment.blank?

    Rails.application.routes.url_helpers.rails_representation_path(logo_attachment.variant(args).processed)
  end

  def thumbnail_file
    logo.attachment
  end

  def self.safe_attributes
    super + [:remove_logo]
  end

  unlocked do
    type [::Hydra::PCDM::Vocab::PCDMTerms.Object, ::TERMS[:ual].community]

    before_destroy :can_be_destroyed?
    before_destroy -> { logo.purge_later }

    validates :title, presence: true

    before_validation do
      self.visibility = JupiterCore::VISIBILITY_PUBLIC
    end

    def can_be_destroyed?
      return true if member_collections.count == 0

      errors.add(:member_collections, :must_be_empty,
                 list_of_collections: member_collections.map(&:title).join(', '))
      throw(:abort)
    end
  end

end
