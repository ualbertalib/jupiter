class Community < JupiterCore::LockedLdpObject

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
  has_attribute :description, ::RDF::Vocab::DC.description, solrize_for: [:search]

  # this method can be used on the SolrCached object OR the ActiveFedora object
  def member_collections
    Collection.where(community_id: id)
  end

  unlocked do
    before_destroy :can_be_destroyed?

    validates :title, presence: true

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
