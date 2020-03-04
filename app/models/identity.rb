class Identity < ApplicationRecord

  has_secure_password validations: false

  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }
  # Check if the password is present only when working with system accounts
  validates :password, presence: true, confirmation: true, if: lambda { |identity|
    identity.provider == 'system'
  }

end
