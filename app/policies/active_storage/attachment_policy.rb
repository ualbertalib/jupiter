class ActiveStorage::AttachmentPolicy < DepositablePolicy

  def file_set?
    api? || admin?
  end

  def fixity_file?
    api? || admin?
  end

  def original_file?
    api? || admin?
  end

end
