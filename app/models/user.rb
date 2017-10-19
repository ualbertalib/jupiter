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
      sanitized_query = "%#{sanitize_sql_like(query.downcase)}%"
      where('lower(name) like ?', sanitized_query).or(User.where('lower(email) like ?', sanitized_query))
    end
  }
  scope :filter, lambda { |filter|
    if filter.present?
      case filter
      when 'user'
        where(admin: false)
      when 'admin'
        where(admin: true)
      when 'active'
        where(suspended: false)
      when 'suspended'
        where(suspended: true)
      end
      # we just ignore everything else (including 'all' -- means unscoped)
    end
  }

  def items
    Item.where(owner: id)
  end

end
