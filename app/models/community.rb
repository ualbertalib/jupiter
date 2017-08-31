class Community < JupiterCore::LockedLdpObject

  # Needed for ActiveStorage (logo)...
  include GlobalID::Identification

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
  has_attribute :description, ::RDF::Vocab::DC.description, solrize_for: [:search]

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where(community_id: id)
  end

  def logo
    @active_storage_attached_logo ||
      (@active_storage_attached_logo = ActiveStorage::Attached::One.new(:logo, self))
  end

  # A virtual attribute to handle removing logos on forms ...
  def remove_logo
    # Never want the checkbox checked by default
    false
  end

  def remove_logo=(val)
    if logo.attached? && (val == "true")
      # This should probably be 'purge_later', but then we have problems on page reload
      logo.attachment.purge
    end
  end

  def self.safe_attributes
    super + [:remove_logo]
  end

  unlocked do
    before_destroy :can_be_destroyed?
    before_destroy -> { logo.purge_later }

    validates :title, presence: true

    before_validation do
      self.visibility = JupiterCore::VISIBILITY_PUBLIC
    end

    def can_be_destroyed?
      return true if member_collections.count == 0
      errors.add(:member_collections,
                 I18n.t('communities.errors.member_collections_must_be_empty',
                        list_of_collections: member_collections.map(&:title).join(', ')))
      throw(:abort)
    end
  end

end
