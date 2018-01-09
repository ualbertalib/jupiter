class ProfilePolicy < ApplicationPolicy

  def index?
    logged_in?
  end

end
