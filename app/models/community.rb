class Community < JupiterCore::LockedLdpObject

  # Needed for ActiveStorage (logo)...
  include GlobalID::Identification

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where(community_id: id)
  end

  def logo
    @active_storage_attached_logo ||
      (@active_storage_attached_logo = ActiveStorage::Attached::One.new(:logo, self))
  end

  unlocked do
    before_destroy :can_be_destroyed?
    before_destroy -> { logo.purge_later }

    before_validation do
      self.visibility = JupiterCore::VISIBILITY_PUBLIC
    end

    def can_be_destroyed?
      return true if member_collections.count == 0
      errors.add(:member_collections, 'must be empty')
      throw(:abort)
    end
  end

end
