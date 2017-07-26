class CollectionPolicy < ApplicationPolicy

  def index?
    true
  end

  def permitted_attributes
    [:visibility, :owner, :title, :community_id] if user.admin?
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      scope.all # Assuming all collections are public
    end

  end

end
