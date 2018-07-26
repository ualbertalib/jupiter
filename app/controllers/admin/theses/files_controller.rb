class Admin::Theses::FilesController < Admin::AdminController

  include DraftFilesActions

  private

  def needs_authorization?
    false
  end

  def draft_class
    DraftThesis
  end

  def item_class
    Thesis
  end

  def file_partial_location
    'admin/theses/draft/_files_list'
  end

end
