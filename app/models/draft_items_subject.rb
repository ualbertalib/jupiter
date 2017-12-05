class DraftItemsSubject < ApplicationRecord

  belongs_to :subject
  belongs_to :draft_item

end
