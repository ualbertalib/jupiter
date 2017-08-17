class User < ApplicationRecord

  paginates_per 15

  has_many :identities, dependent: :destroy
  has_many :site_notifications, dependent: :destroy

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

  def self.search(search)
    # searches name, email
    if search.present?
      where('email LIKE ?', "%#{search}%").or(where('name LIKE ?', "%#{search}%"))
    else
      self
    end
  end

end
