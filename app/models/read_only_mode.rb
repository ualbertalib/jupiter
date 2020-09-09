class ReadOnlyMode < ApplicationRecord

  validate :only_one_record_exists, on: :create
  validates :enabled, inclusion: { in: [true, false] }

  def self.enabled?
    Rails.cache.fetch('read_only_mode.first.enabled', expires_in: 1.minute) do
      ReadOnlyMode.first.enabled
    end
  end

  def self.disabled?
    !enabled?
  end

  def self.enable
    read_only_mode = ReadOnlyMode.first
    read_only_mode.enabled = true
    read_only_mode.save!

    Announcement.new(message: I18n.t('announcement_templates.read_only_mode'), user: User.system_user).save!
  end

  def self.disable
    read_only_mode = ReadOnlyMode.first
    read_only_mode.enabled = false
    read_only_mode.save!
    Announcement.where(user: User.system_user.id).destroy_all
  end

  private

  def only_one_record_exists
    errors.add(:enabled, :only_one_record_exists) if ReadOnlyMode.count > 0
  end

end
