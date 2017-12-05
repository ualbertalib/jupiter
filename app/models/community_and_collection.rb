class CommunityAndCollection < ApplicationRecord

  has_many :draft_items_community_and_collections, dependent: :destroy
  has_many :draft_items, through: :draft_items_community_and_collections

end
