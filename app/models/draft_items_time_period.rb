class DraftItemsTimePeriod < ApplicationRecord

  belongs_to :time_period
  belongs_to :draft_item

end
