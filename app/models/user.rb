class User < ApplicationRecord

  has_secure_password :api_key, validations: false
  has_many :identities, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :draft_items, dependent: :destroy
  has_many :draft_theses, dependent: :destroy

  has_many :items, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :theses, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :collections, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :communities, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

  # User validation for sysatem and api key values
  #             | System | Api key | Valid
  #             ---------------------------
  # Presence(X) |   X    |    X    | True
  #             |        |         | True
  #             |   X    |         | False
  #             |        |    X    | False

  # Check if the api key is there only if the user is a system account
  validates :api_key_digest,
            presence: { message: 'must be present if System value is true' },
            if: -> { system && api_key_digest.blank? }

  # Check that the api key is not present if it is not a system account
  validates :api_key_digest,
            absence: { message: 'must be blank if System value is false' },
            if: -> { !system && api_key_digest.present? }

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
