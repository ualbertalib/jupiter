class AipPolicy < ApplicationPolicy

  def access?
    system? || admin?
  end

end
