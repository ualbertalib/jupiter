class Digitization::BookPolicy < ApplicationPolicy

  def show?
    true
  end

  def thumbnail?
    true
  end

  def download?
    true
  end

end
