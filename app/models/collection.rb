class Collection < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::CollectionBehavior

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
  has_attribute :community_id, ::VOCABULARY[:ualib].path, type: :path, solrize_for: :pathing

  # description for collections

  def community
    Community.find(community_id)
  end

  def path
    "#{community_id}/#{id}"
  end

  def member_items
    Item.where(member_of_paths: path)
  end

  def as_json(_options)
    super(only: [:title, :id])
  end

  unlocked do
    before_destroy :can_be_destroyed?

    before_validation do
      self.visibility = JupiterCore::VISIBILITY_PUBLIC
    end

    def can_be_destroyed?
      return true if member_items.count == 0
      errors.add(:member_items,
                 I18n.t('collections.errors.member_items_must_be_empty',
                        list_of_items: member_items.map(&:title).join(', ')))
      throw(:abort)
    end
  end

end
