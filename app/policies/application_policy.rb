class ApplicationPolicy

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Default behaviour is only admin can access all resources
  def index?
    admin?
  end

  def show?
    index?
  end

  def create?
    admin?
  end

  def new?
    create?
  end

  def update?
    admin?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  def admin?
    user.try(:admin?)
  end

  def system?
    user.try(:system?)
  end

  def logged_in?
    # Note: `ApplicationController#current_user` ensures user isn't suspended
    user.present?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end

  end

end
