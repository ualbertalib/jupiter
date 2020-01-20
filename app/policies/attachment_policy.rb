class AttachmentPolicy < DepositablePolicy

  def file_set?
    user_is_authenticated_for_record?
  end

  def download_file?
    user_is_authenticated_for_record?
  end

  def fixity_file?
    user_is_authenticated_for_record?
  end

  def original_file?
    user_is_authenticated_for_record?
  end

end
