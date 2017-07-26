class AdminPolicy < ApplicationPolicy

  def access?
    admin?
  end

end
