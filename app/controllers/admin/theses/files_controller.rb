class Admin::Theses::FilesController < Admin::AdminController

  include DraftFilesActions

  private

  def authorize?
    false
  end

  def set_draft
    # TODO: reason why we assign to @draft_thesis is because we haven't switched views over yet
    @draft = @draft_thesis = DraftThesis.find(params[:thesis_id])
  end

  def file_partial_location
    'admin/theses/draft/_files_list'
  end

end
