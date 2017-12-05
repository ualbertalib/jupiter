class TimePeriod < ApplicationRecord

  has_many :draft_items_time_periods, dependent: :destroy
  has_many :draft_items, through: :draft_items_time_periods

end
