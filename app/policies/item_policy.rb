class ItemPolicy < LockedLdpObjectPolicy

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
    false
  end

end
