class User < ApplicationRecord

  has_many :identities, dependent: :destroy
  has_many :announcements, dependent: :destroy

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

  scope :search_users, lambda { |query|
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

  def update_activity!(now, remote_ip, sign_in: false)
    raise ArgumentError, :remote_ip if remote_ip.blank?
    raise ArgumentError, :now if now.blank?
    # Is the user signing in now?
    if sign_in
      self.previous_sign_in_at = last_sign_in_at
      self.previous_sign_in_ip = last_sign_in_ip
      self.last_sign_in_at = now
      self.last_sign_in_ip = remote_ip
    end
    self.last_seen_at = now
    self.last_seen_ip = remote_ip
    save!
  end

end
