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

  def self.autocomplete_name_email(query, limit)
    sanitized = sanitize_sql_like(query)
    # Match start of first name, last name, email, hyphenated surnames
    start_of_string = "#{sanitized}%".downcase
    after_space = "% #{sanitized}%".downcase
    after_hyphen = "%-#{sanitized}%".downcase
    User.where('lower(name) like ?', start_of_string)
        .or(User.where('lower(name) like ?', after_space))
        .or(User.where('lower(name) like ?', after_hyphen))
        .or(User.where('lower(email) like ?', start_of_string))
        .limit(limit)
  end

end
