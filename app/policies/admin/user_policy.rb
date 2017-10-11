class Admin::UserPolicy < ApplicationPolicy

  def suspend?
    regular_user? && not_self?
  end

  def unsuspend?
    record.last.suspended?
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
    !record.last.suspended? && !record.last.admin?
  end

  def not_self?
    record.last && user && record.last != user
  end

end
