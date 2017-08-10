class UserPolicy < ApplicationPolicy

  def create?
    false
  end

  def show?
    owned? || admin?
  end

  def update?
    owned? || admin?
  end

  def destroy?
    update?
  end

  def reverse_impersonate?
    record && record.admin? && !record.suspended?
  end

  def owned?
    record && user && record == user
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      scope.all if user.admin?
    end

  end

end
