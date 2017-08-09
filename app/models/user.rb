class User < ApplicationRecord

  paginates_per 15

  has_many :identities, dependent: :destroy

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :display_name, presence: true

  def self.search(search)
    # searches display_name, email
    if search.present?
      where('email LIKE ?', "%#{search}%").or(where('display_name LIKE ?', "%#{search}%"))
    else
      self
    end
  end

end
