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

  # These policies are used for the AIP V1 API. Pundit does not allow use of
  # namespaces

  def show_entity?
    system? || admin?
  end

  def file_sets?
    system? || admin?
  end

  def file_paths?
    system? || admin?
  end

end
