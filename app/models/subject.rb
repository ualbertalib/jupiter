class Subject < ApplicationRecord

  has_many :draft_items_subjects, dependent: :destroy
  has_many :draft_items, through: :draft_items_subjects

end
