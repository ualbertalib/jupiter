# The 2 classes ActiveStorage::AttachmentPolicy and AttachmentPolicy are defined
# because pundit complains that it cannot find the policy for
# ActiveStorage::AttachmentPolicy, but it complains if it cannot find the
# constant AttachmentPolicy. For now this is an ugly workaround.

class ActiveStorage::AttachmentPolicy < DepositablePolicy

  def file_set?
    admin? || user_is_authenticated_for_record?
  end

  def download_file?
    admin? || user_is_authenticated_for_record?
  end

  def fixity_file?
    admin? || user_is_authenticated_for_record?
  end

  def original_file?
    admin? || user_is_authenticated_for_record?
  end

end
