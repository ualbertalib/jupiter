class Admin::AnnouncementsController < Admin::AdminController

  helper_method :current_announcements, :past_announcements

  def new
    @new_announcement = Announcement.new
  end

  def create
    @new_announcement = Announcement.new(announcement_params)
    @new_announcement.user = current_user

    if @new_announcement.save
      # TODO: Flash success?
      redirect_to new_admin_announcement_path
    else
      # TODO: This drops the url to /admin/announcements
      # (without the /new) so a page refresh will 500...which is annoying
      # You could `redirect to new_admin_announcement_path` but you lose the errors object
      # unless you put it in the flash message which is probably okay here?
      render action: 'new'
    end
  end

  def destroy
    announcement = Announcement.find(params[:id])
    announcement.removed_at = Time.current
    announcement.save!

    # TODO: Flash success?
    redirect_to new_admin_announcement_path
  end

  protected

  def current_announcements
    Announcement.current
  end

  def past_announcements
    Announcement.past
  end

  def announcement_params
    params[:announcement].permit(:message)
  end

end
