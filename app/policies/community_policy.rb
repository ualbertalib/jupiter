class CommunityPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def thumbnail?
    true
  end

  def update?
    false
  end

  def edit?
    false
  end

  def destroy?
    false
  end

end
