class RenameSiteNotificationsToAnnouncements < ActiveRecord::Migration[5.1]

  def change
    rename_table :site_notifications, :announcements
  end

end
