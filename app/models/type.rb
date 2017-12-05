class Type < ApplicationRecord

  has_many :draft_items

  def translated_name
    I18n.t(name, scope: [:activerecord, :attributes, :type, :names])
  end

end
