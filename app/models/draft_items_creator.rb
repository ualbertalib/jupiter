class DraftItemsCreator < ApplicationRecord

  belongs_to :creator
  belongs_to :draft_item

end
