class BatchIngest < ApplicationRecord

  enum status: { processing: 0, started: 1, completed: 2 }

  belongs_to :user
  has_many :draft_items, dependent: :nullify

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :files, presence: true

end
