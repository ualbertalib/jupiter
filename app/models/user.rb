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

  def update_activity!(remote_ip, now, sign_in: false)
    raise InvalidParameter, :remote_ip if remote_ip.blank?
    raise InvalidParameter, :now if now.blank?
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
