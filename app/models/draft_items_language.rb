class DraftItemsLanguage < ApplicationRecord

  belongs_to :language
  belongs_to :draft_item

end
