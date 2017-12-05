class Place < ApplicationRecord

  has_many :draft_items_places, dependent: :destroy
  has_many :draft_items, through: :draft_items_places

end
