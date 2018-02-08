class CommunityPolicy < LockedLdpObjectPolicy

  def index?
    true
  end

  def thumbnail?
    true
  end
end
