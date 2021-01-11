class ReadOnlyService

  def enable
    read_only_mode = ReadOnlyMode.first
    read_only_mode.enabled = true
    read_only_mode.save!
    Announcement.new(message: I18n.t('announcement_templates.read_only_mode'), user: User.system_user).save!
  end

  def disable
    read_only_mode = ReadOnlyMode.first
    read_only_mode.enabled = false
    read_only_mode.save!
    User.system_user.announcements.destroy_all
  end

end
