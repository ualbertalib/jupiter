class AttachmentPolicy < DepositablePolicy

  def file_set?
    true
  end

  def download_file?
    true
  end

  def fixity_file?
    true
  end

  def original_file?
    true
  end

end
