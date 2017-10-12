class User < ApplicationRecord

  FILTER_MAP = { all: I18n.t(:all),
                 admin: I18n.t('admin.users.admin_role'),
                 user: I18n.t('admin.users.user_role'),
                 suspended: I18n.t('admin.users.suspended_status'),
                 active: I18n.t('admin.users.active_status') }.freeze

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
      else
        # we just ignore 'all' (means unscoped), fail on everything else
        raise ArgumentError, 'not a valid filter' unless FILTER_MAP.keys.include?(filter.to_sym)
      end
    end
  }

  def items
    Item.where(owner: id)
  end

end
