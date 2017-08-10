class Admin::UserPolicy < ApplicationPolicy

  def block?
    regular_user? && not_self?
  end

  def unblock?
    record.last.blocked?
  end

  def grant_admin?
    regular_user?
  end

  def revoke_admin?
    record.last.admin? && not_self?
  end

  def impersonate?
    regular_user? && not_self?
  end

  protected

  def regular_user?
    !record.last.blocked? && !record.last.admin?
  end

  def not_self?
    record.last && user && record.last != user
  end

end
