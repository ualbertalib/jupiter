class ActiveStorage::AttachmentPolicy < DepositablePolicy

  def file_set?
    system? || admin?
  end

  def fixity_file?
    system? || admin?
  end

  def original_file?
    system? || admin?
  end

end
