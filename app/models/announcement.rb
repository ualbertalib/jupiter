class Announcement < ApplicationRecord

  belongs_to :user

  validates :message, presence: true, length: { maximum: 500 }

  scope :current, -> { where(removed_at: nil).order(created_at: :desc) }
  scope :past, -> { where.not(removed_at: nil).order(removed_at: :desc) }

end
