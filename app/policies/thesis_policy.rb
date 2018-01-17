class ThesisPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def show?
    owned? || admin? || public?
  end

  def new?
    admin?
  end

  def create?
    admin?
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

end
