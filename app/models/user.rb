class User < ApplicationRecord

  has_many :identities, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :draft_items, dependent: :destroy

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

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

  # For masking the ID that we send to rollbar
  def id_as_hash
    Digest::SHA2.hexdigest("#{Rails.application.secrets.secret_key_base}_#{id}")
  end

end
