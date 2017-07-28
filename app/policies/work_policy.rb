class WorkPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def create?
    owned? || admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def owned?
    user.present?
    # TODO: Fix this, how to get owner of works? Currently record (work) has no relationship to a user/creator
    # record && user && record.creator == user.email
  end

end
