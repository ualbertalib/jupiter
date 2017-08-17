class CollectionPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def create?
    admin?
  end

end
