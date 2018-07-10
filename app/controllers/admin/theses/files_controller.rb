class Admin::Theses::FilesController < Admin::AdminController

  include DraftFilesActions

  private

  def authorize?
    false
  end

  def set_draft
    @draft = DraftThesis.find(params[:thesis_id])
  end

  def file_partial_location
    'admin/theses/draft/_files_list'
  end

end
