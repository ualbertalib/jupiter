class ItemPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def show?
    owned? || admin? || public?
  end

  def new?
    user.present?
  end

  def create?
    owned? || admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

end
