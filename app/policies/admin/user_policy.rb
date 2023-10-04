class Admin::UserPolicy < ApplicationPolicy

  def suspend?
    regular_user? && not_self?
  end

  def unsuspend?
    record.suspended?
  end

  def grant_admin?
    regular_user?
  end

  def revoke_admin?
    record.admin? && not_self?
  end

  def login_as_user?
    regular_user? && not_self?
  end

  protected

  def regular_user?
    !record.suspended? && !record.admin?
  end

  def not_self?
    record && user && record != user
  end

end
