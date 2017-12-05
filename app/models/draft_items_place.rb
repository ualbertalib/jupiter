class DraftItemsPlace < ApplicationRecord

  belongs_to :place
  belongs_to :draft_item

end
