class Language < ApplicationRecord

  has_and_belongs_to_many :draft_items

  def translated_name
    I18n.t(name, scope: [:activerecord, :attributes, :language, :names])
  end

end
