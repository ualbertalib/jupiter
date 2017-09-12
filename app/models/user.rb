class User < ApplicationRecord

  has_many :identities, dependent: :destroy
  has_many :site_notifications, dependent: :destroy

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

  scope :search, lambda { |query|
    if query.present?
      where('lower(email) LIKE ?', "%#{query.downcase}%")
        .or(where('lower(name) LIKE ?', "%#{query.downcase}%"))
    end
  }

  def items
    Item.where(owner: id)
  end

end
