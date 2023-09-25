class Announcement < ApplicationRecord

  belongs_to :user

  validates :message, presence: true, length: { maximum: 500 }

  scope :current, -> { where(removed_at: nil).order(created_at: :desc) }
  scope :past, -> { where.not(removed_at: nil).order(removed_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    ['message', 'created_at', 'removed_at']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['user']
  end

end
