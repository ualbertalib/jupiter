class Creator < ApplicationRecord

  has_many :draft_items_creators, dependent: :destroy
  has_many :draft_items, through: :draft_items_creators

end
