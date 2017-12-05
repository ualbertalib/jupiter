class DraftItemsCitation < ApplicationRecord

  belongs_to :citation
  belongs_to :draft_item

end
