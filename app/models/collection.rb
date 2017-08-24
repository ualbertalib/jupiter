class Collection < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::CollectionBehavior

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
  has_attribute :community_id, ::VOCABULARY[:ualib].path, solrize_for: :pathing

  # description for collections

  def community
    Community.find(community_id)
  end

  def path
    "#{community_id}/#{id}"
  end

  def member_works
    Work.where(member_of_paths: path)
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
      return true if member_works.count == 0
      errors.add(:member_works,
                 I18n.t('collections.errors.member_works_must_be_empty',
                        list_of_works: member_works.map(&:title).join(', ')))
      throw(:abort)
    end
  end

end
