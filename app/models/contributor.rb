class Contributor < ApplicationRecord

  has_many :draft_items_contributors, dependent: :destroy
  has_many :draft_items, through: :draft_items_contributors

end
