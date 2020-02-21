class ActiveStorage::AttachmentPolicy < DepositablePolicy

  def file_set?
    admin?
  end

  def fixity_file?
    admin?
  end

  def original_file?
    admin?
  end

end
