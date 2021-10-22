class User < ApplicationRecord

  has_secure_password :api_key, validations: false

  has_many :announcements, dependent: :destroy
  has_many :batch_ingests, dependent: :destroy
  has_many :digitization_metadata_ingests, dependent: :destroy, class_name: 'Digitization::BatchMetadataIngest'
  has_many :draft_items, dependent: :destroy
  has_many :draft_theses, dependent: :destroy
  has_many :identities, dependent: :destroy

  has_many :items, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :theses, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :collections, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :communities, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error

  scope :system_user, -> { find_by(system: true) }

  # We don't need to validate the format of an email address here,
  # as emails are supplied from SAML (so assuming...hopefully they are valid)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }

  validates :name, presence: true

  # User validation for sysatem and api key values
  #             | System | Api key | Valid |
  #             ----------------------------
  # Presence(X) |   X    |    X    | True  |
  #             |        |         | True  |
  #             |   X    |         | False |
  #             |        |    X    | False |
  #             ----------------------------

  # Check if the api key is there only if the user is a system account
  validates :api_key_digest,
            presence: { message: :present_if_system_true },
            if: -> { system && api_key_digest.blank? }

  # Check that the api key is not present if it is not a system account
  validates :api_key_digest,
            absence: { message: :blank_if_system_false },
            if: -> { !system && api_key_digest.present? }

  # Ensure only one system user exists
  validates :system, if: :system, uniqueness: true

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

  def flipper_id
    "User:#{id}"
  end

end
