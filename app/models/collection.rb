class Collection < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::CollectionBehavior

  has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]

  # TODO: this should probably be renamed to share a name with member_of_paths on Item, so that their
  # facet results can be coalesced when Collections are mixed into search results along with Items, as in the
  # main search results
  has_attribute :community_id, ::TERMS[:ual].path,
                type: :path,
                solrize_for: :pathing

  has_attribute :description, ::RDF::Vocab::DC.description, solrize_for: [:search]
  has_multival_attribute :creators, ::RDF::Vocab::DC.creator, solrize_for: :exact_match
  has_attribute :fedora3_uuid, ::TERMS[:ual].fedora3uuid, solrize_for: :exact_match

  additional_search_index :community_title, solrize_for: :sort,
                                            as: -> { Community.find_by(id: community_id)&.title }

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

    validates :title, presence: true
    validates :community_id, presence: true
    validate :community_validations

    before_validation do
      self.visibility = JupiterCore::VISIBILITY_PUBLIC
    end

    before_save do
      community.unlock_and_fetch_ldp_object do |uo|
        self.member_of_collections += [uo]
      end
    end

    def can_be_destroyed?
      return true if member_items.count == 0
      errors.add(:member_items, :must_be_empty,
                 list_of_items: member_items.map(&:title).join(', '))
      throw(:abort)
    end

    def community_validations
      return unless community_id
      community = Community.find_by(community_id)
      errors.add(:community_id, :community_not_found, id: community_id) if community.blank?
    end
  end

end
