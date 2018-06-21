class Institution < ApplicationRecord

  has_many :draft_thesis, dependent: :nullify

  def translated_name
    I18n.t(name, scope: [:activerecord, :attributes, :institution, :names])
  end

end
