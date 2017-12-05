class Citation < ApplicationRecord

  has_many :draft_items_citations, dependent: :destroy
  has_many :draft_items, through: :draft_items_citations

end
