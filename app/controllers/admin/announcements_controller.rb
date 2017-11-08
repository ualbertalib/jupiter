class Admin::AnnouncementsController < Admin::AdminController

  def index
    @current_announcements = Announcement.current

    @search = Announcement.past
                          .ransack(params[:q])

    @search.sorts = 'removed_at desc' if @search.sorts.empty?

    @past_announcements = @search.result.includes(:user)
                                 .page(params[:page])

    @new_announcement = Announcement.new
  end

  def create
    @new_announcement = Announcement.new(announcement_params)
    @new_announcement.user = current_user

    if @new_announcement.save
      redirect_to admin_announcements_path, notice: t('.posted')
    else
      redirect_to admin_announcements_path,
                  alert: t('.post_error_html', error_message: @new_announcement.errors.full_messages.first)
    end
  end

  def destroy
    announcement = Announcement.find(params[:id])
    announcement.removed_at = Time.current
    announcement.save!

    redirect_to admin_announcements_path, notice: t('.removed')
  end

  protected

  def announcement_params
    params[:announcement].permit(:message)
  end

end
