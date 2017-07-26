class CommunityPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end

  def permitted_attributes
    [:visibility, :owner, :title] if user.admin?
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      scope.all # Assuming all communities are public
    end

  end

end
