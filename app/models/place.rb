class Place < ApplicationRecord

  has_and_belongs_to_many :draft_items

end
