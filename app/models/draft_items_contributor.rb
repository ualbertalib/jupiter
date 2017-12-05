class DraftItemsContributor < ApplicationRecord

  belongs_to :contributor
  belongs_to :draft_item

end
