class ThesisPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def show?
    owned? || admin? || public? || record_requires_authentication?
  end

  def new?
    false # There's no interface for this, currently
  end

  def create?
    false # There's no interface for this, currently
  end

  def update?
    false # There's no interface for this, currently
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

end
