class ItemPolicy < DepositablePolicy

  def index?
    true
  end

  def show?
    owned? || admin? || public? || record_requires_authentication?
  end

  def new?
    user.present?
  end

  def create?
    owned? || admin?
  end

  def update?
    create?
  end

  def destroy?
    admin?
  end

  def download?
    admin? || owned? || public? || user_is_authenticated_for_record?
  end

  def thumbnail?
    download?
  end

  # This policy are used for the AIP V1 API. Pundit does not allow use of
  # namespaces in its policies

  def file_sets?
    user_is_authenticated_for_record?
  end

end
